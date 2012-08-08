Marquee beta
---------------

## SYNOPSIS
    
    mojo Marquee [--document_root path] [--dafault_file name]
        [--auto_index] ..

## DESCRIPTION

Marquee�́A�T�[�o�[�T�C�h�C���N���[�h�\��HTTP�T�[�o�[�ł��B
���̃f�B�X�g���r���[�V�����́A�I�u�W�F�N�g�w����Perl API�ƃR�}���h���C��API�ō\������܂��B

## �C���X�g�[��

���L�̃R�}���h�ŃC���X�g�[�����܂��B

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

## Perl API

Marquee�N���X��Mojo���x�[�X�Ƃ��Ă��܂��̂ŁAMojo�̒񋟂�����@�ŃA�v���𓮍삳���܂��B

    use Marquee;
    
    my $app = Marquee->new;
    $app->document_root($path);
    $app->default_file('index.html');
    
    $app->plugin('AutoIndex');
    
    $app->start;

�R�}���h���C���ŉ��L�̂悤�ɋN�����܂��B

    $ ./myapp daemon
    Server available at http://127.0.0.1:3000.

## �R�}���h���C��API

    mojo marquee [OPTIONS]

���L�̃R�}���h�����p�ł��܂�:
  
    -dr, --document_root <path>  �h�L�������g���[�g�̃p�X�����Ă��܂��B�f�t�H���g�̓J�����g�ł��B
    -df, --default_file <name>   �f�t�H���g�̃t�@�C�������w�肵�A�����⊮��L���ɂ��܂��B
    -ai, --auto_index            �I�[�g�C���f�b�N�X��L���ɂ��܂��B�f�t�H���g��0�ł��B
    -ud, --under_development     �T�[�o�[�T�C�h�C���N���[�h�̂��߂̃f�o�b�O�X�N���[����L���ɂ��܂��B
    -b, --backlog <size>         Set listen backlog size, defaults to
                                 SOMAXCONN.
    -c, --clients <number>       Set maximum number of concurrent clients,
                                 defaults to 1000.
    -g, --group <name>           Set group name for process.
    -i, --inactivity <seconds>   Set inactivity timeout, defaults to the value
                                 of MOJO_INACTIVITY_TIMEOUT or 15.
    -l, --listen <location>      Set one or more locations you want to listen
                                 on, defaults to the value of MOJO_LISTEN or
                                 "http://*:3000".
    -p, --proxy                  Activate reverse proxy support, defaults to
                                 the value of MOJO_REVERSE_PROXY.
    -r, --requests <number>      Set maximum number of requests per keep-alive
                                 connection, defaults to 25.
    -u, --user <name>            Set username for process.

### �g�p��1

    $ mojo marquee
    [Mon Oct 17 23:18:35 2011] [info] Server listening (http://*:3000)
    Server available at http://127.0.0.1:3000.

### �g�p��2(�|�[�g�ԍ����w��)

    $ mojo marquee --listen http://*:3001

### �g�p��3(�h�L�������g���[�g���w��)

    $ mojo marquee --document_root ./public

### �g�p��4(�f�t�H���g�t�@�C�������w��)

    $ mojo marquee --default_file index.html

### �g�p��4(�I�[�g�C���f�b�N�X�ƃc���[�\����L����)

    $ mojo marquee --auto_index

![Site list](/jamadam/Marquee/raw/master/screenshot/autoindex.png "Auto Index")

![Site list](/jamadam/Marquee/raw/master/screenshot/autoindextree.png "Auto Index")

## REPOSITORY

[https://github.com/jamadam/Marquee]
[https://github.com/jamadam/Marquee]:https://github.com/jamadam/Marquee

## CREDIT

Icons by [Yusuke Kamiyamane].
[Yusuke Kamiyamane]:http://p.yusukekamiyamane.com/

## COPYRIGHT AND LICENSE

Copyright (c) 2012 [jamadam]
[jamadam]: http://blog2.jamadam.com/

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
