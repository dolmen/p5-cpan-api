package MetaCPAN::Server::Controller::Source;
use Moose;
BEGIN { extends 'MetaCPAN::Server::Controller' }
use Plack::App::Directory;

sub index : Chained('/') : PathPart('source') : CaptureArgs(0) {
}

sub get : Chained('index') : PathPart('') : Args {
    my ( $self, $c, $author, $release, @path ) = @_;
    my $path = join( '/', @path );
    my $file = $c->model('Source')->path( $author, $release, $path )
        or $c->detach('/not_found');
    if ( $file->is_dir ) {
        $path = "/source/$author/$release/$path";
        $path =~ s/\/$//;
        my $env = $c->req->env;
        local $env->{PATH_INFO}   = '/';
        local $env->{SCRIPT_NAME} = $path;
        my $res = Plack::App::Directory->new( { root => $file->stringify } )
            ->to_app->($env);

        $c->res->content_type('text/html');
        $c->res->body( $res->[2]->[0] );
    }
    else {
        $c->res->content_type('text/plain');
        $c->res->body( $file->openr );
    }
}

sub module : Chained('index') : PathPart('') : Args(1) {
    my ( $self, $c, $module ) = @_;
    $module = $c->model('CPAN::File')->inflate(0)->find($module)
        or $c->detach('/not_found');
    $module = $module->{_source};
    $module = $c->stash($module);
    $c->forward( 'get', [ @$module{qw(author release path)} ] );
}

1;
