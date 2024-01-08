//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

pragma experimental ABIEncoderV2;

import "./IEpochs.sol";
import "./Ownable.sol";

//                                                                             hhhhhhh
//                                                                             h:::::h
//                                                                             h:::::h
//                                                                             h:::::h
//     eeeeeeeeeeee    ppppp   ppppppppp      ooooooooooo       cccccccccccccccch::::h hhhhh           ssssssssss
//   ee::::::::::::ee  p::::ppp:::::::::p   oo:::::::::::oo   cc:::::::::::::::ch::::hh:::::hhh      ss::::::::::s
//  e::::::eeeee:::::eep:::::::::::::::::p o:::::::::::::::o c:::::::::::::::::ch::::::::::::::hh  ss:::::::::::::s
// e::::::e     e:::::epp::::::ppppp::::::po:::::ooooo:::::oc:::::::cccccc:::::ch:::::::hhh::::::h s::::::ssss:::::s
// e:::::::eeeee::::::e p:::::p     p:::::po::::o     o::::oc::::::c     ccccccch::::::h   h::::::h s:::::s  ssssss
// e:::::::::::::::::e  p:::::p     p:::::po::::o     o::::oc:::::c             h:::::h     h:::::h   s::::::s
// e::::::eeeeeeeeeee   p:::::p     p:::::po::::o     o::::oc:::::c             h:::::h     h:::::h      s::::::s
// e:::::::e            p:::::p    p::::::po::::o     o::::oc::::::c     ccccccch:::::h     h:::::hssssss   s:::::s
// e::::::::e           p:::::ppppp:::::::po:::::ooooo:::::oc:::::::cccccc:::::ch:::::h     h:::::hs:::::ssss::::::s
//  e::::::::eeeeeeee   p::::::::::::::::p o:::::::::::::::o c:::::::::::::::::ch:::::h     h:::::hs::::::::::::::s
//   ee:::::::::::::e   p::::::::::::::pp   oo:::::::::::oo   cc:::::::::::::::ch:::::h     h:::::h s:::::::::::ss
//     eeeeeeeeeeeeee   p::::::pppppppp       ooooooooooo       cccccccccccccccchhhhhhh     hhhhhhh  sssssssssss
//                      p:::::p
//                      p:::::p
//                     p:::::::p
//                     p:::::::p
//                     p:::::::p
//                     ppppppppp

/// @title Epochs
/// @author jongold.eth
/// @notice parses block numbers in epochs
contract Epochs is IEpochs, Ownable {
    string[12] private epochLabels;

    constructor(string[12] memory _labels) {
        epochLabels = _labels;
    }

    function getEpochLabels() public view override returns (string[12] memory) {
        return epochLabels;
    }

    function setEpochLabels(string[12] memory _labels) public onlyOwner {
        epochLabels = _labels;
    }

    function currentEpochs() public view override returns (uint256[12] memory) {
        return getEpochs(block.number);
    }

    function getEpochs(uint256 blockNumber)
        public
        pure
        override
        returns (uint256[12] memory epochs)
    {
        for (uint256 i = 0; i < 12; i++) {
            uint256 exp = i;
            epochs[i] = 1 + ((blockNumber / 11**exp) % 11);
        }
    }
}
