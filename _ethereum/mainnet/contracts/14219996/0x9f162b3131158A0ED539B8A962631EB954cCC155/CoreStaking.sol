//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "./IERC721.sol";
import "./IERC721Receiver.sol";

contract CoreStaking is IERC721Receiver {
    address public immutable targetAddress;
    uint256 public immutable boostRate;

    uint256 public stakedSupply;

    mapping(address => uint256[]) internal _stakedTokensOfOwner;
    mapping(uint256 => address) public stakedTokenOwners;

    constructor(address _targetAddress, uint256 _boostRate) {
        targetAddress = _targetAddress;
        boostRate = _boostRate;
    }

    // ERC721 Receiever

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // INTERNAL

    function _stake(uint256[] calldata tokenIds) internal {
        stakedSupply += tokenIds.length;
        IERC721 target = IERC721(targetAddress);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                target.ownerOf(tokenId) == msg.sender,
                "You must own the token."
            );

            stakedTokenOwners[tokenId] = msg.sender;

            _stakedTokensOfOwner[msg.sender].push(tokenId);
            target.safeTransferFrom(msg.sender, address(this), tokenId);
        }

        emit Staked(msg.sender, tokenIds.length);
    }

    function _withdraw(uint256[] calldata tokenIds) internal {
        stakedSupply -= tokenIds.length;
        IERC721 target = IERC721(targetAddress);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                stakedTokenOwners[tokenId] == msg.sender,
                "You must own the token."
            );

            stakedTokenOwners[tokenId] = address(0);

            // Remove tokenId from the user staked tokenId list
            uint256[] memory newStakedTokensOfOwner = _stakedTokensOfOwner[
                msg.sender
            ];
            for (uint256 q = 0; q < newStakedTokensOfOwner.length; q++) {
                if (newStakedTokensOfOwner[q] == tokenId) {
                    newStakedTokensOfOwner[q] = newStakedTokensOfOwner[
                        newStakedTokensOfOwner.length - 1
                    ];
                }
            }

            _stakedTokensOfOwner[msg.sender] = newStakedTokensOfOwner;
            _stakedTokensOfOwner[msg.sender].pop();

            target.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        emit Withdrawn(msg.sender, tokenIds.length);
    }

    // EVENTS

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
}
