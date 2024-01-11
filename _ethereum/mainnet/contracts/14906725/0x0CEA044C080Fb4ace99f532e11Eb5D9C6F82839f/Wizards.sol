//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract Wizard is ERC721A("Wizard", "WIZ"), Ownable, ReentrancyGuard {

    mapping(address => uint256) public wizardCount;
    uint256 public Wizards = 7777;
    uint256 public wizardPrice = 0.004 ether;
    uint256 public MAX_PER_WALLET_FREE = 2;
    string public wizardURI = "ipfs://QmZxdRjNXwCdpMBzSHVTFownBREGxcFnhmw6D7FHomGYCF/";
    bool public isPaused;

    constructor(){
        isPaused = true;
    }

    function wizardMaker() external payable nonReentrant {
        require(!isPaused, 'sale paused');
        uint256 _wizards = totalSupply();
        require(_wizards + 1 <= Wizards);
        require(wizardCount[msg.sender] < 1 );
        require(msg.sender == tx.origin);

        _safeMint(msg.sender, 1);
        wizardCount[msg.sender] += 1;
    }

    function wizardCouncil() external payable onlyOwner {
        uint256 _wizards = totalSupply();
        require(_wizards + 111 <= Wizards);
        require(wizardCount[msg.sender] <= 666 );

        _safeMint(msg.sender, 111);
        wizardCount[msg.sender] += 111;
    }
    
    function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
		require(success);
	}
    function changePause() external {
        isPaused = !isPaused;
    }
    function _baseURI() internal virtual override view returns (string memory) {
        return wizardURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }
    
    function updateURI(string memory newWizardURI) external onlyOwner {
        wizardURI = newWizardURI;
    }
}
