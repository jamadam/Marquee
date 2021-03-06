use strict;
use warnings;
use FindBin;
use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), '../lib';
use lib join '/', File::Spec->splitdir(File::Spec->rel2abs(dirname(__FILE__))), 'lib';
use Test::More;
use Data::Dumper;
use Marquee::SSIHandler::EPL;
use Marquee::SSIHandler::EP;
use Benchmark qw( timethese cmpthese countit);
use Mojo::Template;
use Marquee;
use Marquee::Context;
use Marquee::Stash;
use Mojo::Transaction::HTTP;

    no strict 'refs';
    *{'Marquee::SSIHandler::EPL::render_nocache'} = \&epl_render_nocache;
    *{'Marquee::SSIHandler::EP::render_nocache'} = \&ep_render_nocache;
    
    my $file = "$FindBin::Bin/benchmark.epl";
    
    {
        my $renderer = Marquee::SSIHandler::EPL->new;
        
        my $a = countit(1, sub{
            $renderer->render_nocache($file);
        })->iters;
        
        my $b = countit(1, sub{
            $renderer->render($file);
        })->iters;
        
        warn sprintf("EPL Cashe causes %.2f times faster.", $b / $a);
    }
    
    {
        my $app = Marquee->new;
        my $tx  = Mojo::Transaction::HTTP->new;
        local $Marquee::CONTEXT = Marquee::Context->new(app => $app, tx => $tx);
        $Marquee::CONTEXT->stash(Marquee::Stash->new);
        my $renderer = Marquee::SSIHandler::EP->new;
        
        my $a = countit(1, sub{
            $renderer->render_nocache($file);
        })->iters;
        
        my $b = countit(1, sub{
            $renderer->render($file);
        })->iters;
        
        warn sprintf("EP Cashe causes %.2f times faster.", $b / $a);
    }

    ### --
    ### EPL handler
    ### --
    sub epl_render_nocache {
        my ($self, $path) = @_;
        
        my $context = $Marquee::CONTEXT;
        my $mt = Mojo::Template->new;
        my $output = $mt->render_file($path, $self, $context);
        return ref $output ? die $output : $output;
    }

    sub ep_render_nocache {
        my ($self, $path) = @_;
        
        my $context = $Marquee::CONTEXT;
        
        my $mt = Mojo::Template->new();
        $mt->auto_escape(1);
        
        # Be a bit more relaxed for helpers
        my $prepend = q/no strict 'refs'; no warnings 'redefine';/;

        # Helpers
        $prepend .= 'my $_H = shift; my $_F = $_H->funcs;';
        for my $name (sort keys %{$self->funcs}) {
            if ($name =~ /^\w+$/) {
                $prepend .=
                "sub $name; *$name = sub {\$_F->{$name}->(\$_H, \@_)};";
            }
        }
        
        $prepend .= 'use strict;';
        for my $var (keys %{$context->stash}) {
            if ($var =~ /^\w+$/) {
                $prepend .= " my \$$var = stash '$var';";
            }
        }
        $mt->prepend($prepend);
        
        my $output = $mt->render_file($path, $self, $context);
        
        return ref $output ? die $output : $output;
    }
