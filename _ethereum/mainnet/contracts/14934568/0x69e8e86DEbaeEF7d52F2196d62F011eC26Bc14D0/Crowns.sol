// SPDX-License-Identifier: MIT

/**
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░▒█████████▓░░░░░░░░░▓███████▒▒░░░░░░░░░░░
░░░░░░░░░░▓██▓▓▓▓▓█████▒░░░░░▒█████▓▓▓▓██▒░░░░░░░░░░
░░░░░░░░░█▓▒░░░░░░░█████▒░░░▒████▓░░░░░░░▓█░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░███▒░░░░▒████░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░███▓░░░░░░░███▒░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░████▒░░░░░░░░░▒██▒░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░▓███████▒░░░░░░▒███████▓▒░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░▒▓▓█████▒░░░▓█████▓▓░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░█████▒░▒████▓░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░████▓░▒███▓░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░████▒░▒███▓░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░███▒░░░▒███░░░░░░░░░░░░░░░░░░░░
░░░░░░░░▓███▓▓▓▓▓▓▓▓██▒░░░░░░░▓██▓▓▓▓▓▓▓▓▓▓░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Jagwar Twin x CTHDRL
Contract: Jagwar Twin - 33 [Crowns]
Website: https://jagwartwin.com
**/

pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Crowns is Ownable, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIds;

    // Base token and contract URI
    string private _baseTokenURI;
    string private _baseContractURI;

    // End time when minting is no longer available
    uint256 public endTime;

    // Addresses that have minted
    mapping(address => uint16) minted;

    // EIP-721
    // https://eips.ethereum.org/EIPS/eip-721
    constructor() ERC721('Jagwar Twin - 33 [Crowns]', 'JTCRWN') {
        string memory baseTokenURI = 'https://meta.jagwartwin.com/crowns/';
        string
            memory baseContractURI = 'https://meta.jagwartwin.com/jtcrwn-meta';

        _baseTokenURI = baseTokenURI;
        _baseContractURI = baseContractURI;
    }

    // EIP-2981
    // https://eips.ethereum.org/EIPS/eip-2981
    function royaltyInfo(
        uint256, /*tokenId*/
        uint256 _price
    ) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = _price / 7;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Read & set base contract URI
    function contractURI() public view returns (string memory) {
        return _baseContractURI;
    }

    function setContractURI(string memory baseContractURI_) public onlyOwner {
        require(bytes(baseContractURI_).length > 0, 'Invalid baseContractUrl');
        _baseContractURI = baseContractURI_;
    }

    // Read & set baseURI, to be used by base ERC721 tokenURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        require(bytes(baseURI_).length > 0, 'Invalid baseUrl');
        _baseTokenURI = baseURI_;
    }

    // As owner, set end time
    function setEndTime(uint256 endTime_) public onlyOwner {
        endTime = endTime_;
    }

    // Mint function
    function mint() external returns (uint256) {
        require(block.timestamp < endTime, 'Minting is no longer available');
        require(minted[msg.sender] < 1);

        // Inc ID
        tokenIds.increment();
        uint256 _tokenId = tokenIds.current();

        // Mark address claimed
        minted[msg.sender] += 1;

        // Mint & return
        _safeMint(msg.sender, _tokenId);
        return _tokenId;
    }
}
