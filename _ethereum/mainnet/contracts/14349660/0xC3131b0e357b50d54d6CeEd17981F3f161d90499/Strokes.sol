// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./ERC721.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

interface ProxyRegistry {
  function proxies(address) external view returns (address);
}

contract Strokes is ERC721, IERC2981, Ownable {
    using ECDSA for bytes32;
    using Strings for uint256;
    using Strings for uint24;

    ProxyRegistry public immutable proxyRegistry;
    uint256 public totalSupply;
    mapping(uint256 => uint24[10]) public seeds;
    mapping(address => uint256) private _minted;
    string public gatewayURI;
    string public CID;
    string public CIDPreview;
    bool public changedCIDPreview;
    bool public openedPublic;

    constructor(address _proxyRegistry, string memory _gatewayURI, string memory _CID, string memory _CIDPreview) ERC721("Strokes by gmi.sh", "STROKE") {
      proxyRegistry = ProxyRegistry(_proxyRegistry);
      gatewayURI = _gatewayURI;
      CID = _CID;
      CIDPreview = _CIDPreview;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
      return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function contractURI() external view returns (string memory) {
      return string(abi.encodePacked(gatewayURI, CID, "/metadata.json"));
    }

    function isApprovedForAll(address owner, address operator) override(ERC721) public view returns (bool) {
      if (proxyRegistry.proxies(owner) == operator) return true;
      return super.isApprovedForAll(owner, operator);
    }

    function openPublic() external onlyOwner {
      openedPublic = true;
    }

    function updateCIDPreview(string memory _CIDPreview) external onlyOwner {
      require(!changedCIDPreview); //update only once
      changedCIDPreview = true;
      CIDPreview = _CIDPreview;
    }


    /**
     * @dev Updates gateway URI if Pinata has stopped working
     */
    function setGatewayURI(string calldata _gatewayURI) external onlyOwner {
      gatewayURI = _gatewayURI;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
      require(_exists(tokenId), "URI query for nonexistent token");
      uint24[10] memory seed = seeds[tokenId];
      string memory tokenString = tokenId.toString();
      bytes memory seedString;
      for (uint256 i = 0; i < 10; i++) {
        seedString = abi.encodePacked(seedString, i == 0 ? '' : ',', seed[i].toString());
      }
      bytes memory url = abi.encodePacked(gatewayURI, CID, '/?seed=', seedString, '&id=', tokenString);
      return string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked('{"name":"Stroke #', tokenString, ' by gmi.sh", "description":"Stroke #', tokenString, ' is a unique on-chain abstract art piece by [gmi.sh](https://gmi.sh).", "animation_url": "', url, '", "image": "', gatewayURI, CIDPreview, '/', tokenString, '.jpg"}')
          )
        )
     );
    }

    /**
     * @dev Generate SVG fully on-chain
     */
    function generateSVG(uint256 tokenId) public view returns (string memory) {
      require(_exists(tokenId), "URI query for nonexistent token");
      uint24[10] memory seed = seeds[tokenId];
      bytes memory svg = abi.encodePacked(
        '<svg width="1024" height="1024" viewBox="0 0 1024 1024" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
        '<style>',
        'image{mix-blend-mode:multiply;animation:2419200s linear infinite alternate;transform-origin:50% 50%}',
        'image.r0{transform:rotate(0deg);animation-play-state:paused}'
      );
      for (uint256 i = 1; i < 10; i++) {
        bytes memory animation = abi.encodePacked('@keyframes r', i.toString(), '{from {transform: rotate(', i % 2 == 0 ? '-' : '',((block.timestamp % 86400) * 360 / 86400).toString() ,'deg)}to{transform: rotate(', i % 2 == 0 ? '-' : '', ((i + 1) / 2).toString(), 'turn)}}');
        svg = abi.encodePacked(
          svg,
          'image.r', i.toString(), '{animation-name:r', i.toString(), '}',
          animation
        );
      }
      svg = abi.encodePacked(svg, '</style>');
      for (uint256 i = 0; i < 10; i++) {
        if (seed[i] != 0) svg = abi.encodePacked(svg, '<image xlink:href="', gatewayURI, CID, '/', i.toString(), '/', seed[i].toString(), '.jpg" x="0" y="0" class="r', i.toString(), '"/>');
      }
      return string(abi.encodePacked(svg, '</svg>'));
    }

    receive() external payable {}

    function generateSeed(address to, uint256 minted) private pure returns (uint24[10] memory seed) {
      uint256 hash = uint256(keccak256(abi.encodePacked(to, minted)));
      uint8[10] memory count = [33, 15, 15, 15, 15, 15, 15, 15, 45, 22];
      uint8[10] memory percent = [100, 50, 100, 80, 50, 50, 50, 50, 20, 20];
      for (uint256 i = 0; i < 10; i++) {
        seed[i] = uint24(hash >> (24 * i)) % uint24(uint256(count[i]) * (200 - percent[i]) / 100) + 1;
        if (seed[i] > count[i]) seed[i] = 0;
      }
    }

    modifier checkAmount(uint256 amount) {
      require(totalSupply + amount <= 1000, "Max 1000 Strokes");
      require(_minted[msg.sender] + amount <= 10, "Max 10 per wallet");
      _;
   }

    function mintWL(bytes calldata signature, uint256 amount) external payable checkAmount(amount) {
      require(!openedPublic, "Open sale");
      require(msg.value >= amount * 42 * 1e15, "Mint price 0.042 ETH");
      require(keccak256(abi.encodePacked(msg.sender)).toEthSignedMessageHash().recover(signature) == 0x951a4bC1675863C395754Faa2F8c8Ff1594F066F); //signer
      mintTo(msg.sender, amount);
    }

    function mint(uint256 amount) external payable checkAmount(amount) {
      require(openedPublic, "Not opened");
      require(msg.value >= amount * 90 * 1e15, "Mint price 0.090 ETH");
      mintTo(msg.sender, amount);
    }

    function mintSH(uint256 amount) external payable checkAmount(amount) {
      require(openedPublic, "Not opened");
      require(msg.value >= amount * 69 * 1e15, "Mint price 0.069 ETH");
      mintTo(msg.sender, amount);
    }

    function mintTo(address to, uint256 amount) private {
      uint256 minted = _minted[to];
      uint256 supply = totalSupply;
      for (uint256 i = 1; i <= amount; i++) {
        uint256 tokenId = supply + i;
        seeds[tokenId] = generateSeed(to, minted + i);
        _mint(to, tokenId);
      }
      _minted[to] = minted + amount;
      totalSupply = supply + amount;
    }

    function royaltyInfo(uint256, uint256 _salePrice) override external view returns (address receiver, uint256 royaltyAmount) {
      receiver = address(this);
      royaltyAmount = _salePrice / 20; //5%
    }

    function withdraw(address token, uint256 amount) external {
        bool success;
        uint256 half = amount / 2;
        if (token == address(0)) {
            (success, ) = 0x908c5fBae8Dec9202d8fAF7cA0277E50b87ED03B.call{value: half}("");
            require(success);
            (success, ) = 0x599b418AD25C7b11BFB6A9108bb03E0e0FF8e690.call{value: half}("");
            require(success);
        } else {
            success = IERC20(token).transfer(0x908c5fBae8Dec9202d8fAF7cA0277E50b87ED03B, half);
            require(success);
            success = IERC20(token).transfer(0x599b418AD25C7b11BFB6A9108bb03E0e0FF8e690, half);
            require(success);
        }
    }
}
