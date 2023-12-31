// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title POAP Contract for OnChain Voting System
 * @author The Tech Alchemy Team
 * @notice The onChainPoll contract mints NFTs for voters using the POAP contract with their corresponding poll Ids.
 * @dev All function calls are currently implemented without side effects
 */

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./CountersUpgradeable.sol";

import "./POAPInterface.sol";

contract POAP is
    ERC721Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    POAPInterface
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * @dev Counter for maintaining TokenIds
     */
    CountersUpgradeable.Counter public tokenIdCounter;

    /**
     *  @dev Zero Address
     */
    address constant ZERO_ADDRESS = address(0);

    /**
     *  @dev Mapping for maintaing uri for each NFT token based on poll Id and token Id
     */
    mapping(uint256 => string) internal tokenUri;

    /**
     * @dev OnChainPoll contract address
     */
    address internal onChainPollContract;

    /**
     *  @dev Initialize token name and token symbol
     *  @param name Token Name
     *  @param symbol Token Symbol
     */
    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        require(
            bytes(name).length > 0,
            "POAP: Name parameter can not be empty"
        );
        require(
            bytes(symbol).length > 0,
            "POAP: Symbol parameter can not be empty"
        );
        __ERC721_init(name, symbol);
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Mints a new NFT for the poll response.
     * @dev Only the onChainPoll contract's can call this function.
     * @param tokenMetadata The metadata uri for the poll data.
     * @param to The address to mint the NFT.
     */
    function mint(
        string calldata tokenMetadata,
        address to
    ) external override whenNotPaused onlyOnChainPollContract returns (uint256) {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        tokenUri[tokenId] = tokenMetadata;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Updates the onChainPoll contract's address.
     * @dev Only owner can call this function.
     * @param newOnChainPollContract The new address of the onChainPoll contract.
     */
    function updateOnChainPollContract(
        address newOnChainPollContract
    ) external override onlyOwner {
        require(
            newOnChainPollContract != ZERO_ADDRESS,
            "POAP: OnChainPoll address is the zero address"
        );
        require(
            address(onChainPollContract) != newOnChainPollContract,
            "POAP: Same as pervious address"
        );
        onChainPollContract = newOnChainPollContract;

        emit OnChainPollContractUpdated(onChainPollContract);
    }

    /**
     * @notice tokenURI, function is used to check uri of specific token by giving tokenId.
     * @dev tokenURI, function returns the token uri by giving pollId and tokenId. 
     * @param tokenId tokenId is given to the function to get corresponding uri.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "POAP: Non-existent token.");
        return tokenUri[tokenId];
    }

    /**
     * @dev return the onChainPoll contract's address
     * @return onChainPollContract function returns the onChainPoll contract address.
     */
    function getOnChainPollContract() external view returns (address) {
        return address(onChainPollContract);
    }

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() public override onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() public override onlyOwner {
        _unpause();
    }

    modifier onlyOnChainPollContract() {
        require(
            address(onChainPollContract) != ZERO_ADDRESS,
            "POAP: OnChainPoll contract is not set"
        );
        require(
            msg.sender == address(onChainPollContract),
            "POAP: Caller is not onChainPoll contract"
        );
        _;
    }
}