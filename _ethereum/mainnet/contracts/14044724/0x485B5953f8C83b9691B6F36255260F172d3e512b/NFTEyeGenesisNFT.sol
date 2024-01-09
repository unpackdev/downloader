//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract NFTEyeGenesisNFT is ERC721, Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public constant OG_SUPPLY = 128;
    uint256 public constant PUBLIC_SALE_SUPPLY = 1024;
    uint256 public constant PUBLIC_SALE_PRICE = 0.512 ether;

    uint256 private _ogTokenIdCount;
    uint256 private _publicSaleTokenIdCount;

    string private _nftBaseURI = "https://api.nfteye.io/api/nft_meta/";

    constructor() ERC721("NFTEye Genesis Member", "GM") {
        _ogTokenIdCount = 1; 
        _publicSaleTokenIdCount = 129;
    }

    function _baseURI() internal view override returns (string memory) {
        return _nftBaseURI;
    }

    function updateBaseURI(string calldata _nftURI) public onlyOwner {
        _nftBaseURI = _nftURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function publicMint(uint256 count)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        require(count > 0, "Count must be greater than 0.");
        require(
            _publicSaleTokenIdCount.sub(1).add(count) <=
                (PUBLIC_SALE_SUPPLY + OG_SUPPLY),
            "Max supply exceeded."
        );
        require(
            msg.value >= PUBLIC_SALE_PRICE.mul(count),
            "Not enough ETH."
        );

        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, _publicSaleTokenIdCount);
            _publicSaleTokenIdCount = _publicSaleTokenIdCount.add(1);
        }
    }

    function giveaway(address to) public onlyOwner {
        require(_ogTokenIdCount <= OG_SUPPLY, "Exceeds OG reserved supply");
        _safeMint(to, _ogTokenIdCount);
        _ogTokenIdCount = _ogTokenIdCount.add(1);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

}
