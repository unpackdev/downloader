// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./base64.sol";
import "./HexStrings.sol";
import "./NFTSVG.sol";
import "./ERC721GetImageSvg.sol";

contract ChainRunes is ERC721, ERC721URIStorage, ERC721GetImageSvg, Pausable, Ownable, ERC721Burnable {
    uint public constant mintPrice = 0.001 ether;
    string constant _name = "ChainRunes: Ethereum";
    string constant version = "v1";
    uint256 public totalSupply;
    address payable vault = payable(0x8a7259e3719FB094a74B4bEBD8C75Ddb66F5a25C);
    bytes32 private adminPasswordHash = 0x91e217daab8a4585d0beb366ad80504ec039ef604449121f1480fcefb515ee80;

    constructor() ERC721GetImageSvg(_name, "CRUNE") {}

    event Minted(address sender,uint256 tokenId);

    // function safeMint(address to, uint256 tokenId, string memory uri)
    //     public
    //     onlyOwner
    // {
    //     _safeMint(to, tokenId);
    //     setTokenImageSvg(tokenId, "");
    //     //_setTokenURI(tokenId, uri);
    // }

    function mint() external payable {
        _requireNotPaused();
        require(msg.value >= mintPrice, 'No fees provided');
        // prepare
        uint256 tokenId = uint256(uint160(msg.sender));
        string[20] memory hexArray = prepare(tokenId);
        string memory svg = NFTSVG.gengrateSVG(hexArray);

        // mint
        _safeMint(msg.sender, tokenId);
        setTokenImageSvg(tokenId, svg);
        totalSupply++;

        emit Minted(msg.sender, tokenId);
    }

    // function test1() external pure returns(string memory) {
    //     address addr = 0x5Feb661566137024E239658c1171dB8F9c97cd25;
    //     uint256 tokenId = uint256(uint160(addr));
    //     string[20] memory hexArray = prepare(tokenId);
    //     string memory svg = NFTSVG.gengrateSVG(hexArray);

    //     string memory desc = HexStrings.toHexStringNoPrefix(tokenId, 20);
    //     string memory result = constructTokenURI(svg, desc);
    //     return result;
    // }

    // function test2(address newVault, string calldata password, string calldata nextUnlockHash) external returns (address) {
    //     require(vault != newVault, "They are the same.");
        
    //     bytes32 newHash = keccak256(bytes(password));
    //     require(adminPasswordHash == newHash, "Wrong password.");
        
    //     vault = payable(newVault);
    //     adminPasswordHash = HexStrings.fromHex3(nextUnlockHash);
    //     return vault;
    // }

    function getAdminPasswordHash() external view returns (string memory) {
        return HexStrings.toHex(adminPasswordHash);
    }

    function withdraw() public onlyOwner {
        (bool success,) = vault.call{ value: address(this).balance }("");
        require(success, "Withdraw failed!");
    }

    function updateVault(address newVault, string calldata password, string calldata nextUnlockHash) external onlyOwner {
        require(vault != newVault, "They are the same.");

        bytes32 newHash = keccak256(bytes(password));
        require(adminPasswordHash == newHash, "Wrong password.");
        
        vault = payable(newVault);
        adminPasswordHash = HexStrings.fromHex3(nextUnlockHash);
    }

    function getVault() public view returns (address) {
        return vault;
    }

    function burn() external payable {
        uint256 tokenId = uint256(uint160(msg.sender));
        _requireMinted(tokenId);

        deleteToken(tokenId);
        totalSupply--;
        _burn(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        require(_exists(tokenId), "ElementEthereum.tokenURI(): Query for nonexistent token");
        string memory svg = this.getTokenImageSvg(tokenId);
        require(bytes(svg).length > 10);

        string memory desc = HexStrings.toHexStringNoPrefix(tokenId, 20);
        string memory result = constructTokenURI(svg, desc);
        return result;
    }

    function count() public view returns (uint256) {
        return totalSupply;
    }

    function checkMinted(address addr) public view returns (bool) {
        uint256 tokenId = uint256(uint160(addr));
        return _exists(tokenId);
    }

    function minted() public view returns (bool) {
        bool r = checkMinted(msg.sender);
        return r;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721GetImageSvg, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        view
        whenNotPaused
        override
    {
        require(from == address(0) || to == address(0), "Element: Only support burn to blackhole.");
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function prepare(uint256 addrInt)
        private
        pure
        returns
        (string[20] memory) 
    {
        string[20] memory array = HexStrings.toHexStringsArray(addrInt);
        return array;
    }

    function constructTokenURI(string memory svg, string memory description)
        private
        pure
        returns (string memory)
    {
        string memory imageBase64 = Base64.encode(
            bytes(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8" standalone="no"?> <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"> ',
                    svg
                )
            )
        );
        string memory result = string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                imageBase64,
                                '"}'
                            )
                        )
                    )
                )
            );
        return result;
    }

}
