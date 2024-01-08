//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

import "./RewardsInterface.sol";

contract Yield721 is ERC721, ERC721Enumerable, Ownable {
    event RewardClaimed(address owner, uint256 amount, uint256[] tokenIds);

    string private baseURI;
    bool public mintIsActive = false;
    bool public rewardsIsActive = false;
    uint256 public maxSupply;
    uint256 public mintCost;
    uint256 public maxAmountPerBatchMint = 20;
    uint256 public rewardsPerDay = 10 * 10**18;
    uint256 public rewardsBegin;
    uint256 public rewardsEnd;
    uint256 public mintStart;
    mapping(uint256 => uint256) public tokenIdToLastClaimed;
    address public rewardsContractAddress;
    RewardsInterface private rewardsContract;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _mintCost,
        string memory _URI
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        mintCost = _mintCost;
        baseURI = _URI; //In format ipfs://<CID>/
        rewardsBegin = block.timestamp;
    }

    function setRewardsContractAddress(address _contractAddress) external onlyOwner {
        rewardsContractAddress = _contractAddress;
        rewardsContract = RewardsInterface(_contractAddress);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMintCost(uint256 _newMintCost) external onlyOwner {
        mintCost = _newMintCost;
    }

    function setMintStart(uint256 _startTime) external onlyOwner {
        mintStart = _startTime;
    }

    function flipMintIsActive() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function batchMint(uint256 amountToMint) external payable {
        uint256 totalSupply = totalSupply();
        require(mintIsActive == true, "Minting is not active");
        require(block.timestamp > mintStart, "Minting has not started yet");
        require(amountToMint <= maxAmountPerBatchMint, "Too many tokens to mint per batch");
        require(totalSupply + amountToMint < maxSupply, "Not enough supply remaining for mint");
        require(msg.value >= mintCost * amountToMint, "Not enough ether to cover minting amount");
        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, totalSupply + i, "");
        }
    }

    function projectMint(uint256 amountToMint) external onlyOwner {
        uint256 totalSupply = totalSupply();
        require(totalSupply + amountToMint < maxSupply, "Not enough supply remaining for mint");
        for (uint256 i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, totalSupply + i, "");
        }
    }

    function flipRewardsIsActive() external onlyOwner {
        rewardsIsActive = !rewardsIsActive;
    }

    function setRewardsBegin(uint256 _begin) external onlyOwner {
        rewardsBegin = _begin;
    }

    function setRewardsEnd(uint256 _end) external onlyOwner {
        rewardsEnd = _end;
    }

    function setRewardsPerDay(uint256 _rewardsPerDay) external onlyOwner {
        rewardsPerDay = _rewardsPerDay;
    }

    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a < _b ? _a : _b;
    }

    function getDaysInSeconds(uint256 _startTime, uint256 _endTime) internal pure returns (uint256) {
        require(_endTime > _startTime, "Invalid timestamp when calculating reward days");
        return _endTime - _startTime;
    }

    function getPendingRewards(uint256[] memory _tokenIds) external view returns (uint256) {
        uint256 totalDaysInSeconds;
        uint256 currentTime = min(block.timestamp, rewardsEnd);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 startTime = (tokenIdToLastClaimed[tokenId] > 0) ? tokenIdToLastClaimed[tokenId] : rewardsBegin;
            totalDaysInSeconds += getDaysInSeconds(startTime, currentTime);
        }
        return totalDaysInSeconds * rewardsPerDay / 86400;
    }

    function claimRewards(uint256[] memory _tokenIds) external {
        require(rewardsIsActive == true, "Rewards are not active");
        uint256 currentTime = min(block.timestamp, rewardsEnd);
        uint256 totalDaysInSeconds = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            uint256 startTime = (tokenIdToLastClaimed[tokenId] > 0) ? tokenIdToLastClaimed[tokenId] : rewardsBegin;
            require(ownerOf(tokenId) == msg.sender, "Cannot claim rewards for a token that does not belong to you");
            tokenIdToLastClaimed[tokenId] = currentTime; //Reset last claimed timestamp to now or end date;
            totalDaysInSeconds += getDaysInSeconds(startTime, currentTime);
        }
        uint256 totalRewardAmount = totalDaysInSeconds * rewardsPerDay / 86400;
        if (totalRewardAmount > 0) {
            rewardsContract.mint(msg.sender, totalRewardAmount);
            emit RewardClaimed(msg.sender, totalRewardAmount, _tokenIds);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(owner(), _tokenAmount);
    }

    function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
        IERC721(_tokenAddress).safeTransferFrom(address(this), owner(), _tokenId);
    }
}
