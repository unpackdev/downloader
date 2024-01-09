// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ECDSA.sol";

/// @title FudaoverseDAO Collection
/// @author FudaoverseDAO
/// @notice FudaoverseDAO Collection
contract FuDaoVerseDAO is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter public tokenSupply;

    string public baseURI;

    uint256 public cost = 0.088 ether;
    uint256 public maxSupply = 888;

    bool public presaleOpen = false;
    bool public publicSaleOpen = false;
    bool public paused = false;

    mapping(address => uint256) public whitelistAddrToMintAmt;
    mapping(address => uint256) public publicSaleAddrToMintAmt;

    //sale holders
    address[2] public fundRecipients = [
        0xaDDfdc72494E29A131B1d4d6668184840f1Fc30C,
        0xcD7BCAc7Ee5c18d8cC1374B62F09cf67e6432a08
    ];

    uint256[] public receivePercentagePt = [7000]; //distribution in basis points

    // Off-chain whitelist
    address private signerAddress;
    mapping(bytes => bool) private _nonceUsed;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, "FudaoverseDAO: Only EOA");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _newOwner,
        address _signerAddress
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        signerAddress = _signerAddress;
        transferOwnership(_newOwner);
    }

    event PublicMint(address from, uint256 tokenId);
    event WhitelistMint(address from, uint256 tokenId);
    event DevMint(address from, uint256 mintAmount);

    /**
     * @notice Dev Mint - No limit to wallet
     * @dev Contract must not be paused
     * @dev Mint must not exceed max Supply
     */
    function devMint(uint256 _mintAmount) public onlyOwner {
        require(!paused, "FudaoverseDAO: Contract is paused");
        require(
            tokenSupply.current() + _mintAmount <= maxSupply,
            "FudaoverseDAO: Total mint amount exceeded"
        );
        for (uint256 i; i < _mintAmount; i++) {
            tokenSupply.increment();
            _safeMint(msg.sender, tokenSupply.current());
        }
        emit DevMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Public Mint - Only 1 mint per wallet
     * @dev Contract must not be paused
     * @dev Public Sale must be open
     * @dev Mint must not exceed max Supply
     * @dev msg.value must be = mintPrice
     * @dev ETH must be forwarded to treasury
     * @dev Each wallet can only mint once
     */
    function publicMint() public payable onlyEOA {
        require(!paused, "FudaoverseDAO: Contract is paused");
        require(publicSaleOpen, "FudaoverseDAO: Public Sale is not open");
        require(
            tokenSupply.current() + 1 <= maxSupply,
            "FudaoverseDAO: Total mint amount exceeded"
        );
        require(msg.value == cost, "FudaoverseDAO: Insufficient ETH");

        require(
            publicSaleAddrToMintAmt[msg.sender] < 1,
            "FudaoverseDAO: Wallet has already minted"
        );

        publicSaleAddrToMintAmt[msg.sender]++;
        tokenSupply.increment();
        _safeMint(msg.sender, tokenSupply.current());
        emit PublicMint(msg.sender, tokenSupply.current());
    }

    /**
     * @notice Whitelist Only Mint function - Only 1 mint per wallet
     * @dev Contract must not be paused
     * @dev Public Sale must be open
     * @dev Mint must not exceed max Supply
     * @dev Mint Amount must be greater than 0
     * @dev Each wallet can only mint 1
     * @dev msg.value must be = mintPrice * mintAmount
     * @dev ETH will be kept in smart contract
     */
    function whitelistMint(bytes memory signature, bytes memory nonce)
        public
        payable
    {
        require(!paused, "FudaoverseDAO: Contract is paused");

        require(!_nonceUsed[nonce], "FudaoverseDAO: Nonce already used");
        _nonceUsed[nonce] = true;

        require(
            whitelistSigned(msg.sender, nonce, signature),
            "FudaoverseDAO: Invalid signature"
        );
        require(presaleOpen, "FudaoverseDAO: Presale is not open");
        require(
            tokenSupply.current() + 1 <= maxSupply,
            "FudaoverseDAO: Total mint amount exceeded"
        );

        require(msg.value == cost, "FudaoverseDAO: Insufficient ETH");

        require(
            whitelistAddrToMintAmt[msg.sender] < 1,
            "FudaoverseDAO: Wallet has already minted"
        );

        whitelistAddrToMintAmt[msg.sender]++;
        tokenSupply.increment();
        _safeMint(msg.sender, tokenSupply.current());
        emit WhitelistMint(msg.sender, tokenSupply.current());
    }

    /**
     * @notice Returns metadata URI for sepecified token id
     * @param tokenId Token Id to retrieve metadata
     * @return Metadata URI
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Checks if the the signature is signed by a valid signer for whitelists
     * @param sender Address of minter
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     */
    function whitelistSigned(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return signerAddress == hash.recover(signature);
    }

    /**
     * @dev Set Presale state
     */
    function setPresale(bool _state) public onlyOwner {
        presaleOpen = _state;
    }

    /**
     * @dev Set Public Sale state
     */
    function setPublicSale(bool _state) public onlyOwner {
        publicSaleOpen = _state;
    }

    /**
     * @dev Set Revealed Metadata URI
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @dev Switches pause state to `_state`
     * @param _state Pause State
     */
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /**
     * @dev Emergency Function to withdraw any ETH deposited to this contract
     */
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /**
     * @dev retrieve base URI internally
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev requires currentBalance of contract to have some amount
     * @dev withdraws with the fixed define distribution
     */
    function withdrawFund() public onlyOwner {
        uint256 currentBal = address(this).balance;
        require(currentBal > 0);
        for (uint256 i = 0; i < fundRecipients.length - 1; i++) {
            _withdraw(
                fundRecipients[i],
                (currentBal * receivePercentagePt[i]) / 10000
            );
        }
        //final address receives remainder to prevent ether dust
        _withdraw(
            fundRecipients[fundRecipients.length - 1],
            address(this).balance
        );
    }

    /**
     * @dev private function utilized by withdrawFund
     * @param _addr Address of receiver
     * @param _amt Amount to withdraw
     */
    function _withdraw(address _addr, uint256 _amt) private {
        (bool success, ) = _addr.call{value: _amt}("");
        require(success, "Transfer failed");
    }
}
