package MetaCPAN::Server::Model::CPAN;

use Moose;
extends 'Catalyst::Model';
with 'CatalystX::Component::Traits';

use MetaCPAN::Model;

__PACKAGE__->config( index => 'cpan' );

has esx_model => ( is => 'ro', lazy_build => 1, handles => ['es'] );
has index => ( is => 'ro' );

sub _build_esx_model {
    MetaCPAN::Model->new;
}

sub BUILD {
    my ( $self, $args ) = @_;
    my $index = $self->esx_model->index( $self->index );
    my $class = $self->_original_class_name;
    while ( my ( $k, $v ) = each %{ $index->types } ) {
        no strict 'refs';
        my $classname = "${class}::" . ucfirst($k);
        *{"${classname}::ACCEPT_CONTEXT"} = sub {
            return $index->type($k);
        };
    }
}

1;
