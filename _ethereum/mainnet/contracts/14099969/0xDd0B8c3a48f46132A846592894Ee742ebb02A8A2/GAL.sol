// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./IERC721.sol";

contract GrandApeLegacy is Ownable, ERC721Enumerable {
    mapping(address => uint256) public whitelistsOf;

    uint256 public constant PRICE = 0.088 ether;
    uint256 public constant MAXSUPPLY = 10000;
    uint256 public constant MAX_MINT_PER_TX = 3;
    
    uint256 public saleStage = 1;

    address public immutable deployer;
    address public galStaking;

    string private baseURI;

    modifier onlyOD() {
        require(msg.sender == deployer || msg.sender == owner(), "Go away!");
        _;
    }

    constructor() ERC721("Grand Ape Legacy", "GAL") {
        _setBaseURI("ipfs://QmPxmPtF75jvzU3oTnFUWhtr2MiAadhsEjN18su8ojTBX7/");
        deployer = msg.sender;
    }

    function mintGiveaway(address to, uint256 _count) external onlyOD() {
        uint256 supply = totalSupply();
        require(supply + _count <= MAXSUPPLY, "Insufficient tokens");

        for(uint256 i = 0; i < _count; i++) {
            _safeMint(to, supply + i);
        }   
    }

    function mintWhitelist(uint256 _count) external payable {
        require(saleStage % 3 == 0, "Mint pass sale not active");
        require(whitelistsOf[msg.sender] >= 0, "You are not whitelisted");

        require(_count <= whitelistsOf[msg.sender], "Count too high");
        require(msg.value == PRICE * _count, "Incorrect ETH amount");

        uint256 supply = totalSupply();
        require(supply + _count <= MAXSUPPLY, "Insufficient tokens");

        whitelistsOf[msg.sender] -= _count;
        for(uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function mint(uint256 _count) external payable {
        require(saleStage % 5 == 0, "Public sale not active");

        require(_count <= MAX_MINT_PER_TX, "Max 3 mints allowed");
        require(msg.value == PRICE * _count, "Incorrect ETH amount");

        uint256 supply = totalSupply();
        require(supply + _count <= MAXSUPPLY, "Insufficient tokens");

        for(uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function addWhitelist(address[] memory _wallets) external onlyOD() {
        for(uint256 i = 0; i < _wallets.length; i++)
            whitelistsOf[_wallets[i]] = 2;
    }

    function removeWhitelist(address[] memory _wallets) external onlyOD() {
        for(uint256 i = 0; i < _wallets.length; i++)
            whitelistsOf[_wallets[i]] = 0;
    }

    function setSaleStage(uint256 _stage) external onlyOD() {
        saleStage = _stage;
    }

    function setBaseURI(string memory newBaseURI) external onlyOD() {
        _setBaseURI(newBaseURI);
    }

    function setGALStaking(address staking) external onlyOD() {
        galStaking = staking;
    }

    function withdraw() external onlyOD() {
        payable(deployer).transfer(address(this).balance / 20);
        payable(owner()).transfer(address(this).balance);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function _setBaseURI(string memory newBaseURI) internal {
        baseURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return (operator == galStaking || super.isApprovedForAll(owner, operator));
    }
}
