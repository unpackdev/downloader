// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";

contract TestNft is ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable {
    using Strings for uint256;
    string private baseURI;
    address public operator;
    uint256 constant ONE_MILLION = 1_000_000;

    event NewProject(uint256 indexed projectId);
    event UpdateProject(uint256 indexed projectId);

    struct ProjectInfo {
        uint256 id;
        uint256 currentSupply;
        uint256 maxSupply;
        string baseURI;
        bool isValid;
    }

    mapping(uint256 => ProjectInfo) public projectInfos;

    mapping(uint256 => uint256) public tokenToProject;
    
    function initialize(string memory name_, string memory symbol_, string memory baseUrl_) initializer public {
        __ERC721_init(name_, symbol_);
        __Pausable_init();
        __Ownable_init();
        baseURI = baseUrl_;
    }

    modifier onlyOperator() {
        require(_msgSender() == operator, "Restricted to operator");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function changeBaseURI(string memory newBaseURI) external {
        baseURI = newBaseURI;
    }

    function transferOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "NFT: new operator is the zero address");
        require(newOperator != operator, "NFT: same operator");
        operator = newOperator;
    }

    function setProject(uint256 projectId, uint256 maxSupply, string memory baseUrl) external onlyOwner {
        require(projectInfos[projectId].isValid == false, "NFT: this project is exist");
        projectInfos[projectId] = ProjectInfo(projectId, projectId * ONE_MILLION, maxSupply, baseUrl, true);

        emit NewProject(projectId);
    }

    function updateProject(uint256 projectId, uint256 maxSupply, string memory baseUrl) external onlyOwner {
        require(projectInfos[projectId].isValid, "NFT: this project is invalid");

        projectInfos[projectId].maxSupply = maxSupply;
        projectInfos[projectId].baseURI = baseUrl;

        emit UpdateProject(projectId);
    }

    function changeProjectBaseURI(uint256 projectId, string memory newBaseURI) external {
        require(projectInfos[projectId].isValid, "NFT: this project is invalid");
        projectInfos[projectId].baseURI = newBaseURI;
    }

    function mint(address to, uint256 projectId, address from) external onlyOperator returns (uint256) {
        
        uint256 tokenId = projectInfos[projectId].currentSupply;

        require(tokenId < projectId * ONE_MILLION + projectInfos[projectId].maxSupply - 1, "reach max");

        _safeMint(to, tokenId);

        unchecked {
            projectInfos[projectId].currentSupply += 1;
        }

        tokenToProject[tokenId] = projectId;

        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        _requireMinted(tokenId);
        uint256 projectId = tokenToProject[tokenId];
        require(projectInfos[projectId].isValid, "not valid");

        if (bytes(projectInfos[projectId].baseURI).length == 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        }

        return string(abi.encodePacked(projectInfos[projectId].baseURI, tokenId.toString()));
    }
}