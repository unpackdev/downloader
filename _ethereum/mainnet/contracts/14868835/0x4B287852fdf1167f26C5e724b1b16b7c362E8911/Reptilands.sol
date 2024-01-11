/// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract Reptilands is ERC721, Pausable, AccessControl {
    using Strings for uint256;
    using Counters for Counters.Counter;

    /// VARIABLES

    /**
     *  @notice Counter used for the total token supply
     */
    Counters.Counter public supply;

    /**
     *  @notice Strings used for the prefix of the Tokens and Unrevealed
     */
    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;
    
    /**
     *  @notice Uint's used for the mint cost, the max amount of token, max amount of token per mint transaction
     *          and the mint limits of every sub-colection
     */
    uint256 public cost = 0.1 ether;
    uint256 public constant maxSupply = 4098;
    uint256 public maxMintAmountPerTx = 5;
    uint256 public limitFirstMint = 2042;
    uint256 public limitSecondMint = 4098;

    /**
     *  @notice Bool used for knowing if the tokens are revealed or not
     */
    bool public revealed = false;

    /**
     *  @notice Enum used for tracking the state of the mint
     */
    State public state = State.NOT_STARTED;

    /**
     *  @notice Mapping used for keeping a track of the users who can mint before the contract starts
     */
    mapping(address => uint) public firstWhitelist;
    mapping(address => uint) public secondWhitelist;

    /**
     *  @notice Bytes32 used for roles in the Dapp
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    /**
     *  @notice Payable account used for withdraw the balance of the contract
     */
    address payable public recipientAddress;

    /// STATES
    /**
     *  @notice Enum used for tracking the state of the mint
     */
    enum State {
        NOT_STARTED,
        FIRST_WHITELIST,
        FIRST_MINT_STARTED,
        SECOND_WHITELIST,
        SECOND_MINT_STARTED
    }

    /// MODIFIERS
    /**
     *  @notice Modifier function that verifies that you are minting the right amount
     *  @notice You cannot mint more than the max amount allowed per transaction
     *  @notice You cannot mint less than 1 token
     *  @param _mintAmount is the amount of tokens trying to be minted
     */
    modifier mintCompliance(uint256 _mintAmount) {
        require(state != State.NOT_STARTED, "Mint is not started");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    /**
     *  @notice Modifier function that verifies that you can mint
     *  @notice You cannot mint more than the limit of the stage
     *  @param _mintAmount is the amount of tokens trying to be minted
     *  @param _objective is the address trying to mint
     */
    modifier mintAllowance(uint256 _mintAmount, address _objective) {
        uint256 actualSupply = supply.current();

        if (state == State.FIRST_WHITELIST) {
            uint256 objectiveFirstWhitelist = firstWhitelist[_objective];

            require(_mintAmount <= objectiveFirstWhitelist, "You're exceded the amount allowed to mint in this whitelist");
            require(actualSupply + _mintAmount <= limitFirstMint, "First mint limit reached");
        } else if (state == State.FIRST_MINT_STARTED) {
            require(actualSupply + _mintAmount <= limitFirstMint, "First mint limit reached");
        } else if (state == State.SECOND_WHITELIST) {
            uint256 objectiveSecondWhitelist = secondWhitelist[_objective];

            require(_mintAmount <= objectiveSecondWhitelist, "You're exceded the amount allowed to mint in this whitelist");
            require(actualSupply + _mintAmount <= limitSecondMint, "Second mint limit reached");
        } else {
            require(actualSupply + _mintAmount <= limitSecondMint, "Second mint limit reached");
        }

        _;
    }

    /// FUNCTIONS
    /**
     *  @notice Constructor function that initialice the contract and set de Hidden Uri
     */
    constructor(string memory _hiddenMetadataUri) ERC721("Reptilands", "REPT") {
        _grantRole(ADMIN_ROLE, msg.sender);
        setHiddenMetadataUri(_hiddenMetadataUri);
    }

    /**
     *  @notice Function that allows to mint one or more tokens
     *  @notice The contract cannot be paused
     *  @param _mintAmount is the amount of tokens to be minted by the address in this transaction
     */
    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
        whenNotPaused
        mintAllowance(_mintAmount, msg.sender)
    {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        (bool success, ) = msg.sender.call{value: msg.value - cost * _mintAmount}("");
        require(success, "Devolution failed");

        if (state == State.FIRST_WHITELIST) {
            firstWhitelist[msg.sender] -= _mintAmount;
        }
        if (state == State.SECOND_WHITELIST) {
            secondWhitelist[msg.sender] -= _mintAmount;
        }

        _mintLoop(msg.sender, _mintAmount);
    }
    
    /**
     *  @notice Function that allows the admin to mint for another address
     *  @param _mintAmount is the amount of tokens to be minted to the address by the admin
     *  @param _receiver is the address that will receive the tokens
     */
    function mintForAddress(uint256 _mintAmount, address _receiver)
        public
        mintCompliance(_mintAmount)
        whenNotPaused
        onlyRole(ADMIN_ROLE)
    {
        _mintLoop(_receiver, _mintAmount);
    }

    /**
     *  @notice Set function for the variable revealed
     */
    function setRevealed(bool _state) public onlyRole(ADMIN_ROLE) {
        revealed = _state;
    }

    /**
     *  @notice Set function for the variable cost
     */
    function setCost(uint256 _cost) public onlyRole(ADMIN_ROLE) {
        require(_cost >= 0.05 ether);
        cost = _cost;
    }

    /**
     *  @notice Set function for the variable maxMintAmountPerTx
     */
    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyRole(ADMIN_ROLE) {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    /**
     *  @notice Set function for the variable hiddenMetadataUri
     */
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyRole(ADMIN_ROLE) {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    /**
     *  @notice Set function for the variable uriPrefix
     */
    function setUriPrefix(string memory _uriPrefix) public onlyRole(ADMIN_ROLE) {
        uriPrefix = _uriPrefix;
    }

    /**
     *  @notice Set function for the variable uriSuffix
     */
    function setUriSuffix(string memory _uriSuffix) public onlyRole(ADMIN_ROLE) {
        uriSuffix = _uriSuffix;
    }

    /**
     *  @notice Function for pause the contract
     */
    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     *  @notice Function for unpause the contract
     */
    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     *  @notice Set function for the whitelist
     *  @param _objective is the address that will be setted up in the whitelist
     *  @param _amount is the uint for set the amount of mint available for next whitelist
     */
    function setAddressInWhitelist(address _objective, uint _amount, uint _whitelist) public onlyRole(ADMIN_ROLE) {
        if(_whitelist == 1) {
            firstWhitelist[_objective] = _amount;
        } else if (_whitelist == 2) {
            secondWhitelist[_objective] = _amount;
        } else {
            revert("Wrong whitelist number");
        }
    }

    /**
     *  @notice Function that allow the admins to set the State of the contract
     */
    function setState(uint _state) public onlyRole(ADMIN_ROLE) {
        if (_state == 0) {
            state = State.NOT_STARTED;
        } else if (_state == 1) {
            state = State.FIRST_WHITELIST;
        } else if (_state == 2) {
            state = State.FIRST_MINT_STARTED;
        } else if (_state == 3) {
            state = State.SECOND_WHITELIST;
        } else if (_state == 4) {
            state = State.SECOND_MINT_STARTED;
        } else {
            revert("Wrong state");
        }
    }

    /**
     *  @notice Set function for the limitFirstMint
     *  @param _limit is the new limit allowed for first mint
     */
    function setLimitFirstMint(uint _limit) public onlyRole(ADMIN_ROLE) {
        limitFirstMint = _limit;
    }

    /**
     *  @notice Set function for the limitSecondMint
     *  @param _limit is the new limit allowed for second mint
     */
    function setLimitSecondMint(uint _limit) public onlyRole(ADMIN_ROLE) {
        limitSecondMint = _limit;
    }

    /**
     *  @notice Function that allow the admins to withdraw all the funds
     */
    function withdraw() public onlyRole(ADMIN_ROLE) {
        (bool success, ) = recipientAddress.call{value: address(this).balance}("");
        require(success, "Withdraw call failed");
    }

    /**
     *  @notice Set function for the recipientAddress
     *  @param _recipientAddress is the new address which will receive the funds of the withdraw function
     */
    function setRecipientAddress(address _recipientAddress) public onlyRole(ADMIN_ROLE) {
        recipientAddress = payable(_recipientAddress);
    }

    /**
     *  @notice Function overrider for solving collission between ERC721 and AccessControl
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     *  @notice Function that returns the current supply
     */
    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    /**
     *  @notice Function that allows to see the wallet for an address
     *  @param _owner is the address to consult
     *  @return an array of uint256 with all the ID's that belong to the address
     */
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    /**
     *  @notice Function that returns the URI for the token
     *  @notice If the contract has not revealed yet, this will return the hidden uri
     *  @param _tokenId is the ID of the token for retrieve his URI
     *  @return an string with the correct URI
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }

    /**
     *  @notice Function that create a bool to check if a account address has the role admin
     *  @param _account is the address to check
     *  @return a bool, true if have the role, false otherwise
     */ 
    function isAdmin(address _account) public virtual view returns(bool) {
        return hasRole(ADMIN_ROLE, _account);
    }

    /**
     *  @notice Function that allow to mint several tokens at once
     *  @param _receiver is the address that will receive the tokens
     *  @param _mintAmount is the ammount of tokens to be minted
     */
    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    /**
     *  @notice Internal function that returns the uriPrefix
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}