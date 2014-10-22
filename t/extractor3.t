use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Chloro::Test::NoNameExtractor;

my $form = Chloro::Test::NoNameExtractor->new();

{
    my $set = $form->process(
        params => {
            foo => 42,
        }
    );

    is_deeply(
        $set->results_as_hash(),
        { foo => 42 },
        'foo is extracted from from form'
    );

    is_deeply(
        $set->result_for('foo')->param_names(),
        [],
        'foo field has no param_names'
    );
}

done_testing();
