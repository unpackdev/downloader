pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./math.sol";

interface ManagerLike {
    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);
}

interface VatLike {
    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function gem(bytes32, address) external view returns (uint256);
}

interface PipLike {
    function peek() external view returns (bytes32, bool);
}

interface SpotLike {
    function ilks(bytes32) external view returns (PipLike, uint256);
}

contract Variables {
    ManagerLike public constant managerContract =
        ManagerLike(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    SpotLike public constant spotContract =
        SpotLike(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);
    VatLike public constant vatContract =
        VatLike(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
}

contract VaultResolver is Variables, DSMath {
    function getOwner(uint256 id) public view returns (address owner) {
        owner = managerContract.owns(id);
    }

    function getPosition(
        uint256 id,
        uint256 rewardAmount,
        uint256 networthAmount
    ) public view returns (
        uint256 claimableRewardAmount,
        uint256 claimableNetworth
    ) {
        address urn = managerContract.urns(id);
        bytes32 ilk = managerContract.ilks(id);

        (uint256 ink, uint256 art) = vatContract.urns(ilk, urn);
        (, uint256 rate, uint256 priceMargin, , ) = vatContract.ilks(ilk);

        (, uint256 mat) = spotContract.ilks(ilk);
        uint256 price = rmul(priceMargin, mat);
        price = price / 1e9;

        uint256 supply = wmul(ink, price);
        uint256 borrow = rmul(art, rate);

        claimableNetworth = sub(supply, borrow);

        if (networthAmount > claimableNetworth) {
            claimableRewardAmount = wdiv(claimableNetworth, networthAmount);
            claimableRewardAmount = wmul(rewardAmount, claimableRewardAmount);
        } else {
            claimableRewardAmount = rewardAmount;
        }
    }
}

contract InstaMakerDAOMerkleResolver is VaultResolver {
    string public constant name = "MakerDAO-Merkle-Resolver-v1.0";
}


