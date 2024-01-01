// SPDX-License-Identifier: WAGDIE


pragma solidity >=0.6.0 <0.9.0;

import "./IERC1155.sol";
import "./IERC721.sol";
import "./Address.sol";

interface IConcordToken is IERC1155 {
    function burn(address account, uint256 id, uint256 amount) external;
}

interface IWagdieWorld {
    struct WagdieInfo {
        uint64 locationIdCur;
        address owner;
        uint32 emptySpace;
    }

    function wagdieIdToInfo(uint16) external view returns (WagdieInfo memory);
}

contract CureWAGDIE {
    IConcordToken public concordToken = IConcordToken(0x1d38150f1Fd989Fb89Ab19518A9C4E93C5554634);
    IERC721 public wagdieToken = IERC721(0x659A4BdaAaCc62d2bd9Cb18225D9C89b5B697A5A);

    address wagdieWorldAddress = 0x616D4635ceCf94597690Cab0Fc159c3A8231C904;

    uint256 private constant cure = 43;

    event WAGDIECured(address indexed user, uint256 wagdieId);

    function cureWAGDIE(uint256 wagdieId) external {
        require(concordToken.balanceOf(msg.sender, cure) > 0, "You must have a cure token");

        if (msg.sender != wagdieToken.ownerOf(wagdieId)) {
            require(
                msg.sender == IWagdieWorld(wagdieWorldAddress).wagdieIdToInfo(uint16(wagdieId)).owner,
                "Not Character Owner"
            );
        }

        concordToken.burn(msg.sender, cure, 1);

        emit WAGDIECured(msg.sender, wagdieId);
    }
}