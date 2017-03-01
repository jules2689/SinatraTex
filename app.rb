require 'rubygems'
require 'sinatra/base'
require 'digest'
require 'json'

configure {
  set :server, :puma
}

class DiaTex < Sinatra::Base
  def log(type, msg)
    remote_ip = request.ip
    date = Time.now.strftime('%d/%b/%Y %T %Z')
    f = open(LOGFILE, 'a')
    f.write("%s [%s] %s \"%s\"\n" % [remote_ip, date, type, msg])
    f.close
  end

  # The png conversion is based on Thomas Pelletier's Tex2Png (https://github.com/pelletier/tex2png), thanks for the bacon!
  get '/latex/png' do
    # LaTeX document skeleton
    document_top = "\\documentclass{article}
    \\usepackage{stix}
    \\usepackage{mathtools}
    \\everymath{\\displaystyle}
    \\begin{document}
    \\pagestyle{empty}
    $"

    document_bottom = "$
    \\end{document}"

    # Document resolution, hardcoded.
    resolution = 119

    tex = params[:tex]

    # Prepare data
    m = Digest::MD5.new
    m.update('%s' % [tex])
    uid = m.hexdigest

    # Compute the resulting png path
    png_path = '%s/%s.png' % [TEMP_PNG, uid]

    # This file already exists
    if File.exist?(png_path)
      # Return existing image
      log('render png', '%s' % [tex])
      content_type 'image/png'
      return File.read(File.join(png_path))
    end

    # Assemble the complete document source code (head + corp + foot)
    complete_tex_doc = '%s%s%s' % [document_top, tex, document_bottom]

    # Write the tex file
    tex_path = '%s/%s.tex' % [TEMP_TEX, uid]
    tex_file = File.open(tex_path, 'w')
    tex_file.write(complete_tex_doc)
    tex_file.close

    # Convert to dvi
    system('latex --interaction=nonstopmode -output-directory=%s %s' % [TEMP_DVI, tex_path])
    log('render png', '%s' % [tex])

    # We do not need the tex file anymore
    system('rm %s' % [tex_path])

    # Compute the complete dvi file path
    dvi_path = '%s/%s.dvi' % [TEMP_DVI, uid]

    # The compilation succeeded, have fun with png
    if File.exist?(dvi_path)

      # Convert to png
      system('dvipng -T tight -bg Transparent -D %s -o %s %s' % [resolution, png_path, dvi_path])

      # Remove the dvi file
      system('rm %s' % [dvi_path])

      # Return the result of our beautiful work
      content_type 'image/png'
      File.read(File.join(png_path))
    else
      dvi_log_path = '%s/%s.log' % [TEMP_DVI, uid]
      log('error', 'The compilation failed, see %s in the dvi temporary directory' % [dvi_log_path])
    end
  end
end
