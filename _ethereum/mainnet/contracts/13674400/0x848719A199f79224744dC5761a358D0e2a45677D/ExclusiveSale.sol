//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./draft-EIP712.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./IAvatar.sol";
import "./IDava.sol";
import "./IRandomBox.sol";

interface IPartCollection {
    function unsafeMintBatch(
        address account,
        uint256[] calldata partIds,
        uint256[] calldata amounts
    ) external;
}

contract ExclusiveSale is EIP712, Ownable {
    bytes32 public constant TYPE_HASH =
        keccak256("Ticket(uint256 price,uint16 amount,address beneficiary)");

    uint16 public constant PARTS_PER_AVATAR = 3;
    uint32 public constant CLOSING_TIME = 1638316800;

    uint16 internal _nextAvatarId = 499;

    // Parts
    IDava public dava;
    IPartCollection public davaOfficial;
    IRandomBox private _randomBox;

    mapping(address => bool) public participated;

    struct Ticket {
        uint256 price;
        uint16 amount;
        address beneficiary;
    }

    struct MintReq {
        uint8 vSig;
        bytes32 rSig;
        bytes32 sSig;
        Ticket ticket;
    }

    constructor(
        IDava dava_,
        IPartCollection davaOfficial_,
        IRandomBox randomBox_
    ) EIP712("ExclusiveSale", "V1") {
        dava = dava_;
        davaOfficial = davaOfficial_;
        _randomBox = randomBox_;
    }

    modifier onlyBeforeClosing() {
        require(block.timestamp < CLOSING_TIME, "ExclusiveSale: sale closed");
        _;
    }

    function mint(MintReq calldata mintReq) external payable onlyBeforeClosing {
        require(
            !participated[msg.sender],
            "ExclusiveSale: already participated"
        );
        require(
            msg.sender == mintReq.ticket.beneficiary,
            "ExclusiveSale: not authorized"
        );
        require(
            msg.value == mintReq.ticket.price,
            "ExclusiveSale: unmatched price"
        );
        _verifySig(mintReq);

        participated[msg.sender] = true;

        for (uint16 i = 0; i < mintReq.ticket.amount; i++) {
            _mintAvatarWithParts(_nextAvatarId - i);
        }
        _nextAvatarId -= mintReq.ticket.amount;
    }

    function withdrawFunds(address payable receiver) external onlyOwner {
        uint256 amount = address(this).balance;
        receiver.transfer(amount);
    }

    function _mintAvatarWithParts(uint16 avatarId) internal {
        address avatar = dava.mint(address(this), uint256(avatarId));

        uint256[] memory partIds = _randomBox.getPartIds(avatarId);
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;

        davaOfficial.unsafeMintBatch(avatar, partIds, amounts);
        Part[] memory parts = new Part[](PARTS_PER_AVATAR);
        for (uint16 i = 0; i < PARTS_PER_AVATAR; i += 1) {
            parts[i] = Part(address(davaOfficial), uint96(partIds[i]));
        }
        IAvatar(avatar).dress(parts, new bytes32[](0));
        dava.transferFrom(address(this), msg.sender, avatarId);
    }

    function _verifySig(MintReq calldata mintReq) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    mintReq.ticket.price,
                    mintReq.ticket.amount,
                    msg.sender
                )
            )
        );

        address signer = ecrecover(
            digest,
            mintReq.vSig,
            mintReq.rSig,
            mintReq.sSig
        );
        require(signer == owner(), "ExclusiveSale: invalid signature");
    }
}
