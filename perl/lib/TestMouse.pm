package TestMouse;

use Mouse;

has attr_ro => (
	is  => 'ro',
	isa => 'Int',
);

has attr_rw => (
	is  => 'rw',
	isa => 'Str',
);

has maybe => (
	is  => 'ro',
	isa => 'Maybe[Int]',
);

has class => (
	is  => 'ro',
	isa => 'ClassName',
);

has maybe_class => (
	is  => 'ro',
	isa => 'Maybe[ClassName]',
);

has list => (
	is  => 'ro',
	isa => 'ArrayRef',
	default => sub { ["olo", 8, "lo"] },
);

has hash => (
	is  => 'ro',
	isa => 'HashRef',
	default => sub { { key1 => "value1", key2 => 50, key3 => "v3" } },
);

#! SWIFT do_something: doSomething(_: Int, _: String) -> String
sub do_something {
	my ($self, $int, $str) = @_;
	return sprintf "%d - %s", $int + $self->attr_ro, $str . $self->attr_rw;
}

no Mouse;
__PACKAGE__->meta->make_immutable;
