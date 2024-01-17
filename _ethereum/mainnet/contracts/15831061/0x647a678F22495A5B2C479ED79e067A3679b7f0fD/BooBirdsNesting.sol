// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";


contract BooBirdsNesting is Ownable, IERC721Receiver {
    event BirdsNested(address indexed from, uint16[] tokenIds);
    event LeftNest(address indexed to, uint16[] tokenIds);

    struct Nest {
        uint48 time;
        uint16[] tokenIds;
    }

    IERC721 public baseToken;

    mapping(address => Nest) internal nests;

    constructor(IERC721 _baseToken) {
        baseToken = _baseToken;
    }

    function nestBirds(uint16[] calldata ids) external {
        require(ids.length > 0, "Nesting: must be nesting more than 0 birds");

        Nest memory nest = nests[msg.sender];

        if (nest.time != 0) {
            for (uint256 i; i < ids.length; i++) {
                baseToken.transferFrom(msg.sender, address(this), ids[i]);
                nests[msg.sender].tokenIds.push(ids[i]);
            }
        } else {
            uint48 nestedTimestamp = uint48(block.timestamp);

            for (uint256 i; i < ids.length; i++) {
                baseToken.transferFrom(msg.sender, address(this), ids[i]);
            }

            nests[msg.sender] = Nest({
                time: nestedTimestamp,
                tokenIds: ids
            });
        }

        emit BirdsNested(msg.sender, ids);
    }

    function leaveNest() external {
        Nest memory nest = nests[msg.sender];
        require(nest.time != 0, "Nesting: you have no birds nested");

        for (uint256 i; i < nest.tokenIds.length; i++) {
            baseToken.transferFrom(
                address(this),
                msg.sender,
                nest.tokenIds[i]
            );
        }

        delete nests[msg.sender];

        emit LeftNest(msg.sender, nest.tokenIds);
    }

    function nestedOf(address who) public view returns (Nest memory) {
        return nests[who];
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        revert("Nesting: invalid");
    }
}
