contract AirdropHelper {

    function airdropFrom(IERC721 erc721, uint[] calldata tokenIds, address[] calldata tos) external {
        require(msg.sender == 0x993F42634C113E478244452a453505a26fbB121b, "403");
        require(tokenIds.length == tos.length, "ERR");
        for (uint i = 0; i < tos.length; i++) {
            erc721.transferFrom(msg.sender, tos[i], tokenIds[i]);
        }
    }

}

interface IERC721 {

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}