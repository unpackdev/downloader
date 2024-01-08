pragma solidity ^0.7.3;

import "./ERC721.sol";

contract RedditAvatarNftOG is ERC721 {
  constructor() public ERC721("RedditNFT", "SNOO") {
    address o = 0x70417e99F63C0eeD3b5Ba95B23d35EF08cD004C7;

    _mint(o, 1);
    _setTokenURI(1, "https://ipfs.io/ipfs/QmZTY5zaW4kjgiayiNg4kU6AVFsxror624Ahbm9QSokPXY");
    _mint(o, 2);
    _setTokenURI(2, "https://ipfs.io/ipfs/QmTa4uVkq1raBfAfKHPjajomELHvBQCPYKUCHCUS9Thh1C");
  }

  function contractURI() public view returns (string memory) {
    return "https://ipfs.io/ipfs/QmaqSi87rFL8YP19uomrLK7VS6JbVQ973Pz9sAhPqtCAfp";
  }
}
