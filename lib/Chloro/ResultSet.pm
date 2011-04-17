package Chloro::ResultSet;
BEGIN {
  $Chloro::ResultSet::VERSION = '0.02';
}

use Moose;
use MooseX::StrictConstructor;

use namespace::autoclean;

use Chloro::Error::Form;
use Chloro::Types qw( ArrayRef Bool HashRef );
use List::AllUtils qw( any );

with 'Chloro::Role::ResultSet';

has _form_errors => (
    traits   => ['Array'],
    isa      => ArrayRef ['Chloro::Error::Form'],
    init_arg => 'form_errors',
    required => 1,
    handles  => {
        form_errors      => 'elements',
        _has_form_errors => 'count',
    },
);

has _params => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => 'params',
    required => 1,
);

has is_valid => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_is_valid',
);

sub _build_is_valid {
    my $self = shift;

    return 0 if $self->_has_form_errors();

    return 0 if any { ! $_->is_valid() } $self->_result_values();

    return 1;
}

sub results_as_hash {
    my $self = shift;

    return $self->_results_hash();
}

sub secure_results_as_hash {
    my $self = shift;

    return $self->_results_hash('skip secure');
}

sub _results_hash {
    my $self        = shift;
    my $skip_secure = shift;

    my %hash;

    for my $result ( $self->_result_values() ) {
        if ( $result->can('group') ) {
            $hash{ $result->group()->name() }{ $result->key() }
                = { $result->key_value_pairs($skip_secure) };

            my $rep_vals
                = $self->_params()->{ $result->group()->repetition_key() };

            $hash{ $result->group()->repetition_key() }
                = ref $rep_vals ? $rep_vals : [$rep_vals];
        }
        else {
            next if $skip_secure && $result->field()->is_secure();

            %hash = ( %hash, $result->key_value_pairs() );
        }
    }

    return \%hash;
}

sub field_errors {
    my $self = shift;

    my %errors;
    for my $result ( grep { !$_->is_valid() } $self->_result_values() ) {
        if ( $result->can('group') ) {
            for my $field_result ( grep { !$_->is_valid() }
                $result->_result_values() ) {

                my $key = join q{.}, $result->prefix(),
                    $field_result->field()->name();

                $errors{$key} = [ $field_result->errors() ];
            }
        }
        else {
            $errors{ $result->field()->name() } = [ $result->errors() ];
        }
    }

    return %errors;
}

sub all_errors {
    my $self = shift;

    my %field_errors = $self->field_errors();

    return $self->form_errors(), map { @{$_} } values %field_errors;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: The set of results from processing a form submission



=pod

=head1 NAME

Chloro::ResultSet - The set of results from processing a form submission

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    my $resultset = $form->process( params => $params );

    if ( $resultset->is_valid() ) {
        do_something( $resultset->results_as_hash() ):
    }
    else {
        # handle errors
    }

=head1 DESCRIPTION

This class represents the set of results from processing an entire form
submission.

This includes results for individual fields and for groups, as well as
validation errors for the form as a whole.

=head1 METHODS

This class has the following methods:

=head2 Chloro::ResultSet->new()

The constructor accepts the following arguments:

=over 4

=item * form_errors

This must be an array reference of L<Chloro::Error::Form> objects. It is
required, but can be empty.

=item * params

This must be a hash reference. This represents the raw user-submitted data,
before any munging.

=item * results

This should be a hash reference.

The keys can either be field names or group prefixes, and the values can be
either L<Chloro::Result::Field> or L<Chloro::Result::Group> objects.

=back

=head2 $resultset->results()

Returns a list of L<Chloro::Result::Field> and L<Chloro::Result::Group>
objects.

=head2 $resultset->result_for($key)

Given a field name or a group prefix, returns a L<Chloro::Result::Field> or
L<Chloro::Result::Group> object

=head2 $resultset->is_valid()

This returns true if there are no field or form errors in this resultset.

=head2 $resultset->results_as_hash()

This takes all the result objects as assembles them into a data hash
reference. See L<Chloro::Manual::Groups> for details on how group results are
returned.

=head2 $resultset->secure_results_as_hash()

This is just like C<< $resultset->results_as_hash() >>, but the result for any
field marked as secure is omitted. This is useful if you need to pass the form
data in a query string or session, and you don't want to include things like
credit card numbers or passwords.

=head2 $resultset->form_errors()

Returns a list of L<Chloro::Error::Form> objects. This list may be empty.

=head2 $resultset->field_errors()

This returns a hash of errors associated with the fields. The hash keys are
either plain field names, or a prefixed name for fields in groups. The value
for each key is an array reference of error objects.

Fields without errors are not included in the hash.

=head2 $resultset->all_errors()

This method returns all the errors in the resultset, both form and field. They
are returned a list.

=head1 ROLES

This class does the L<Chloro::Role::Result> and L<Chloro::Role::ResultSet>
role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

