import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC721.sol";

pragma solidity ^0.8.7;

/**
 * @title The Layoff of 2022
 * @author Laidoff
 */
contract Layoff2022 is ERC721, Pausable, Ownable, ReentrancyGuard {
    event Donate(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event Reward(address indexed account, uint256 tokenId, uint256 amount);
    event BaseURIChanged(string newBaseURI);
    event ContractSealed();

    uint256 public constant MAX_TOKEN = 1000;
    uint256 public constant MIN_REWARD = 10000000000000000; // 0.01eth

    string public revealingURI;
    string public baseURI;
    bool public contractSealed;
    uint256 private _reward_token_id = 1;
    uint256 private _numberMinted;

    constructor(string memory baseURI_) ERC721("Layoff2022", "LOF") {
        baseURI = baseURI_;
    }

    /***********************************|
    |               Core                |
    |__________________________________*/

    /**
     * @notice giveaway is used for airdropping to specific addresses.
     * @param addresses_ the target address of airdrop
     */
    function giveawayList(address[] calldata addresses_) external onlyOwner nonReentrant {
        require(addresses_.length > 0, "empty address list");
        require(_numberMinted + addresses_.length <= MAX_TOKEN, "max supply exceeded");
        for (uint256 i = 0; i < addresses_.length; i++) {
            require(addresses_[i] != address(0), "zero address");
            uint256 tokenId = _numberMinted + 1;
            _safeMint(addresses_[i], tokenId);
            _numberMinted += 1;
        }
    }

    /**
     * @notice giveaway is used for airdropping to specific addresses.
     * @param address_ the target address of airdrop
     */
    function giveaway(address address_) external onlyOwner nonReentrant {
        require(address_ != address(0), "zero address");
        require(_numberMinted + 1 <= MAX_TOKEN, "max supply exceeded");
        uint256 tokenId = _numberMinted + 1;
        _safeMint(address_, tokenId);
        _numberMinted += 1;
    }

    /**
     * @notice issuer have permission to burn token.
     * @param tokenIds_ list of tokenId
     */
    function burn(uint256[] calldata tokenIds_) external onlyOwner nonReentrant  {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _burn(tokenIds_[i]);
        }
    }

    /**
     * @notice anyone has permission to donate ETH into the contract
     */
    function donate() external payable nonReentrant {
        emit Donate(_msgSender(), msg.value);
    }

    /**
     * @notice issuer can withdraws ETH stored in the contract through this method.
     * Cannot withdraw if sealed.
     */
    function withdraw() external onlyOwner nonReentrant notSealed {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit Withdraw(_msgSender(), balance);
    }

    /***********************************|
    |             Getter                |
    |__________________________________*/

    /**
     * @notice totalMinted is used to return the total number of tokens minted. 
     * Note that it does not decrease as the token is burnt.
     */
    function totalMinted() public view returns (uint256) {
        return _numberMinted;
    }

    /**
     * @notice _baseURI is used to override the _baseURI method.
     * @return baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /***********************************|
    |             Setter                |
    |__________________________________*/

    /**
     * @notice setBaseURI is used to set the base URI in special cases.
     * @param baseURI_ baseURI
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit BaseURIChanged(baseURI_);
    }


    /***********************************|
    |          Pause & Hooks            |
    |__________________________________*/

    /**
     * @notice hook function, used to reward holder
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        uint256 poolAmount = address(this).balance;
        if(_numberMinted > 0 && poolAmount > MIN_REWARD) {
            uint256 averageRewardAmount = poolAmount / MAX_TOKEN;
            uint256 rewardAmount = averageRewardAmount > MIN_REWARD? averageRewardAmount: MIN_REWARD;
            address rewardAddress = ownerOf(_reward_token_id);
            _reward_token_id += 1;
            if (_reward_token_id > _numberMinted) {
                _reward_token_id = 1;
            }
            if (rewardAddress != address(0)) {
                payable(rewardAddress).transfer(rewardAmount);
                emit Reward(rewardAddress, _reward_token_id, rewardAmount);
            }
        }
        super._afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice for the purpose of protecting user assets, under extreme conditions, 
     * the circulation of all tokens in the contract needs to be frozen.
     * This process is under the supervision of the community.
     */
    function emergencyPause() external onlyOwner notSealed {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() external onlyOwner notSealed {
        _unpause();
    }

    /**
     * @notice when the project is stable enough, the issuer will call sealContract 
     * to give up the permission to call emergencyPause and unpause.
     */
    function sealContract() external onlyOwner {
        contractSealed = true;
        emit ContractSealed();
    }

    /***********************************|
    |              Modifier             |
    |__________________________________*/

    /**
     * @notice function call is only allowed when the contract has not been sealed
     */
    modifier notSealed() {
        require(!contractSealed, "contract sealed");
        _;
    }
}