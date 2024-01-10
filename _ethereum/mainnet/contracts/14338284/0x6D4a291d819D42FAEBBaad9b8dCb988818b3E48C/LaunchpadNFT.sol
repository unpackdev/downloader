//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

// all launchpad NFT need to support EIP165,ERC721,ERC721Metadata,ERC721Enumerable,Ownable
// this a demon NFT
contract LaunchpadNFT is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string public baseURI;
    string public suffix;

    // must impl this in your NFT contract, and make it public
    uint256 public LAUNCH_MAX_SUPPLY;    // max launch supply
    uint256 public LAUNCH_SUPPLY;        // current launch supply

    address public LAUNCHPAD;

    modifier onlyLaunchpad() {
        require(LAUNCHPAD != address(0), "launchpad address must set");
        require(msg.sender == LAUNCHPAD, "must call by launchpad");
        _;
    }

    function getMaxLaunchpadSupply() view external returns (uint256) {
        return LAUNCH_MAX_SUPPLY;
    }

    function getLaunchpadSupply() view external returns (uint256) {
        return LAUNCH_SUPPLY;
    }
    // end

    constructor(string memory name_, string memory symbol_, string memory baseURI_, string memory suffix_, address launchpad, uint256 maxSupply) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        suffix = suffix_;
        LAUNCHPAD = launchpad;
        LAUNCH_MAX_SUPPLY = maxSupply;
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return string(abi.encodePacked(baseURI, tokenId.toString(), suffix));
    }

    // you must impl this in your NFT contract
    // you NFT contract is responsible to maintain the tokenId
    // you may have another mint function hold by yourself, to skip the process after presale end
    // max size will be 10
    function mintTo(address to, uint size) external onlyLaunchpad {
        require(to != address(0), "can't mint to empty address");
        require(size > 0, "size must greater than zero");
        require(LAUNCH_SUPPLY + size <= LAUNCH_MAX_SUPPLY, "max supply reached");

        for (uint256 i=1; i <= size; i++) {
            _safeMint(to, ERC721Enumerable.totalSupply() + i);
            LAUNCH_SUPPLY++;
        }
    }
}
