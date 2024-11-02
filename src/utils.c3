module snake_boiler::utils;

import std::io;

macro @print_type(value)
{
    var $Type = $typeof(value);

    $if $Type.kindof != STRUCT:
        io::print(value);

    $else

        io::print("{\n");
        $foreach ($i, $member : $Type.membersof)
            $if $i > 0:
                io::print(",\n");
            $endif

            $if $member.nameof != "":
                io::printf("    %s : ", $member.nameof);
                @print_type($member.get(value));
            $endif   
        $endforeach

        io::print("\n}\n");

    $endif
}
