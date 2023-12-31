// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/**
 * @title POAP Contract for LoveHate Voting System
 * @notice The lovehatePoll contract mints NFTs for voters using the POAP contract with their corresponding poll Ids.
 * @dev All function calls are currently implemented without side effects
 */

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./CountersUpgradeable.sol";

interface POAPInterface {
    /**
     * @dev Emitted when NFT is minted.
     */
    event NewNFTMinted(uint256[], uint256[]);

    /**
     * @dev Emitted when the lovehatePoll contract is updated, along with updated lovehatePoll contract address.
     */
    event LoveHatePollContractUpdated(address lovehatePollContract);

    /**
     * @dev Mints a new NFT for the poll response.
     * @dev Only the lovehatePoll contract can call this function.
     * @param tokenUri The metadata uri for the poll data.
     * @param to The address to mint the NFT.
     */
    function mint(
        string calldata tokenUri,
        address to
    ) external returns (uint256);

    /**
     * @dev Updates the lovehatePoll contract's address.
     * @dev Only owner can call this function.
     * @param newLoveHatePollContract The new address of the lovehatePoll contract.
     */
    function updateLoveHatePollContract(
        address newLoveHatePollContract
    ) external;

    /**
     * @dev return the lovehatePoll contract's address
     */
    function getLoveHatePollContract() external returns (address);

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external;

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external;
}

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
     * @dev LoveHatePoll contract address
     */
    address internal lovehatePollContract;

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
     * @dev Only the lovehatePoll contract's can call this function.
     * @param tokenMetadata The metadata uri for the poll data.
     * @param to The address to mint the NFT.
     */
    function mint(
        string calldata tokenMetadata,
        address to
    )
        external
        override
        whenNotPaused
        onlyLoveHatePollContract
        returns (uint256)
    {
        tokenIdCounter.increment();
        uint256 tokenId = tokenIdCounter.current();
        tokenUri[tokenId] = tokenMetadata;
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     * @dev Updates the lovehatePoll contract's address.
     * @dev Only owner can call this function.
     * @param newLoveHatePollContract The new address of the lovehatePoll contract.
     */
    function updateLoveHatePollContract(
        address newLoveHatePollContract
    ) external override onlyOwner {
        require(
            newLoveHatePollContract != ZERO_ADDRESS,
            "POAP: LoveHatePoll address is the zero address"
        );
        require(
            address(lovehatePollContract) != newLoveHatePollContract,
            "POAP: Same as pervious address"
        );
        lovehatePollContract = newLoveHatePollContract;

        emit LoveHatePollContractUpdated(lovehatePollContract);
    }

    /**
     * @notice tokenURI, function is used to check uri of specific token by giving tokenId.
     * @dev tokenURI, function returns the token uri by giving pollId and tokenId.
     * @param tokenId tokenId is given to the function to get corresponding uri.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "POAP: Non-existent token.");
        return tokenUri[tokenId];
    }

    /**
     * @dev return the lovehatePoll contract's address
     * @return lovehatePollContract function returns the lovehatePoll contract address.
     */
    function getLoveHatePollContract() external view returns (address) {
        return address(lovehatePollContract);
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

    modifier onlyLoveHatePollContract() {
        require(
            address(lovehatePollContract) != ZERO_ADDRESS,
            "POAP: LoveHatePoll contract is not set"
        );
        require(
            msg.sender == address(lovehatePollContract),
            "POAP: Caller is not lovehatePoll contract"
        );
        _;
    }
}
