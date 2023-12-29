// SPDX-License-Identifier: MIT

/// @title Laurence Fuller ~ Transient Poems by Laurence Fuller
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                                            ◹◺
◹◺    ////////////////////////////////////////////////////    ◹◺
◹◺    //                                                //    ◹◺
◹◺    //                                                //    ◹◺
◹◺    //                                                //    ◹◺
◹◺    //           _,--._.-,                            //    ◹◺
◹◺    //          /\_r-,\_ )                            //    ◹◺
◹◺    //       .-.) _;='_/ (.;                          //    ◹◺
◹◺    //        \ \'     \/S )                          //    ◹◺
◹◺    //         L.'-. _.'|-'                           //    ◹◺
◹◺    //        <_`-'\'_.'/                             //    ◹◺
◹◺    //          `'-._( \                              //    ◹◺
◹◺    //                 \\       ___                   //    ◹◺
◹◺    //                  \\   .-'_. /                  //    ◹◺
◹◺    //                   \\ /.-'_.'                   //    ◹◺
◹◺    //                    \('--' 	                    //    ◹◺
◹◺    //    Poetic Cinematic Fine Art,                  //    ◹◺
◹◺    //    by Laurence Fuller                          //    ◹◺
◹◺    //                                                //    ◹◺
◹◺    //                                                //    ◹◺
◹◺    //                                                //    ◹◺
◹◺                                                            ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import "./TLCreator.sol";

contract LaurenceFullerTransientPoems is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "Laurence Fuller ~ Transient Poems",
        "LFTP",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}
