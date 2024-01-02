// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IERC1155 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract EnsBurner {
    address burnAddress = 0x000000000000000000000000000000000000dEaD;
    address EnsErc721 = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;
    address EnsNamewrapper = 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401;

    event EnsBurned(address indexed burner, uint256[] tokenIds);

    function burnErc721(uint256[] memory _tokenIds) public {
        IERC721 token = IERC721(EnsErc721);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(token.ownerOf(_tokenIds[i]) == msg.sender, "Caller is not owner of the token");
            token.safeTransferFrom(msg.sender, burnAddress, _tokenIds[i]);
        }

        emit EnsBurned(msg.sender, _tokenIds);
    }

    function burnErc1155(uint256[] memory _tokenIds) public {
        IERC1155 tokenERC1155 = IERC1155(EnsNamewrapper);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(tokenERC1155.ownerOf(_tokenIds[i]) == msg.sender, "Caller is not owner of the token");
            tokenERC1155.safeTransferFrom(msg.sender, burnAddress, _tokenIds[i], 1, "");
        }

        emit EnsBurned(msg.sender, _tokenIds);
    }
}