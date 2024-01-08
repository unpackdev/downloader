// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ERC1155.sol";

/*******************************************************************
 * go ye, Sinners, and shine the light of Plenty onto the world,   *
 * for It is daRk and full of sIn.  tell Them who revel in poverty *
 * and >discord< to repent and unite in wealth. -- 66:14, CoE      *
 *******************************************************************/

//
// Badge of Honor - Upvoting/Downvoting of Identities for EVM-based Networks
//
// Wallets May Be Anonymous. Behaviour Is Not.
//

enum BadgeType {
    Badass,
    Asshole
}

contract BadgeOfHonor is ERC1155 {
    event BadassAwarded(address indexed to, address indexed from, uint256 indexed qt);
    event AssholeAwarded(address indexed to, address indexed from, uint256 indexed qt);
    string private constant BADASS_URI = "https://arweave.net/tRe8Y2pTQzDis2Wp6Rmh0RUVQ0p5zhyJL3uocokFYRs";
    string private constant ASSHOLE_URI = "https://arweave.net/vLFz2LGEIIyNe-oWLawbvfhIE_EtDRSkDmrNM872I40";

    uint256 public fee;
    address public owner;

    constructor(uint256 fee_) {
        fee = fee_;
        owner = msg.sender;
    }

    function award(
        address to,
        BadgeType badge,
        uint256 qt
    ) external payable {
        require(qt > 0, "InvalidQuantity");
        require(fee * qt == msg.value, "InvalidETHAmount");

        ERC1155._mint(to, uint256(badge), qt, "");

        if (badge == BadgeType.Badass) {
            emit BadassAwarded(to, msg.sender, qt);
        } else {
            emit AssholeAwarded(to, msg.sender, qt);
        }
    }

    function uri(uint256 id)
        public
        pure
        returns (string memory)
    {
        return (id == uint256(BadgeType.Badass)) ? BADASS_URI : ASSHOLE_URI;
    }

    function setFee(uint256 fee_) external {
        _enforceOnlyOwner();
        fee = fee_;
    }

    function withdraw() external {
        _enforceOnlyOwner();
        payable(msg.sender).transfer(address(this).balance);
    }

    function _enforceOnlyOwner() internal view {
        require(msg.sender == owner, "UnauthorizedAccess");
    }
}
