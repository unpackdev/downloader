//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Metadata.sol";
import "./ERC721AQueryable.sol";
import "./IERC721Metadata.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

/*
----------------------------------------------------------------------------------------------------
▎▋▚█▘█▞▓▜█▆█▃▃░░▛░▜▖▐█▙▌▊▞░▗▒▊▕▁▖▌▇▎▕▅▁▐▌▅▖▐█▆▞▁▖▛▖▅▁
▋▊▀▃▝▊▖▜▁▂▃▍▖▉▌▃▔▒▙▃▘▟▁▘▓▚▍▘▜▚▇▅▅▇▆▀▓▚▜▒▝▟▝░▆▉▔▚▙▊▛▎▉
▛▓▒▓▌▌▛▓▐▀▗▐░▒▉▂▌█▝▝▍▆▎▇▝▙▁▌▀▜▓▛▎▅▌▜▐▇▌▝▅▃▌▗▕▖▗▟▜▕▜▉▛
▙▟░▃▀▌▔▙▙▗▅▓▆▊▟▃░▁▍▅▔▁▜▔▞░▍▅▊▗▕▁▖▅▄▔▐▘▋▉▐░▜▔▚▚▘█▙▃▍▌▅
▁▙▌▄▃▁▘▄▕▝▆▇▋▞▓▕▋▃▎▀▛▆▖▃▟▙░▌▜▙█▛▒▕▀▕▔▘▗▉▓▝░▞▙▃░▅▄▀▅▀▆
▙▋▇▒▉▙▇▛▌▒▍▀▛▄▇▒▟▖█▘▗▘▒▚▘▀▘▒▙▀▋▉▎▘▓▒▝▋░▁▗▎▒▚▙▗▄▒▊▍▒▂▅
▐▗▀▘▍▌▘▒▙▘▒▊░▆▛▛░▜▒▗▔▒▎▓▚▒▃▌▋▄▒▛▛▐▒▉▜▒▔▓▝▁▝▋█▖▄▗▒▅▍▄▕
▘▙▚▜█▓▖▘▂▝▒▇░▄▅░▟▎▗▕▔▍▅▗▙▇▉▔▜▖▀▓▌▘▌▕█▂▊▋▟▚▓▎▞▖▟▛▅▖▍▗▁
▘▕▌▕▊▌▅▗▂▒▉▊▕▒▔▒▋▇▀▇▛▝▂▞░▍▓▒▁▞▊▗▓▗▉▛▁▎▐▃▁▙▋▔▊▀▅▔▅▄▛▀▟
▉▐▀█▎▊▟▟▟▉▛▀▖█▁▗▀▋██▋▎▝▎░▘▌▐▔▉▞▝▚▟▅▆▉▄▅▇▋▞▇▂▇▇▗▇▓▀▐▜▌
▒▒▒░░░░░░░░░░▒░░░▒░░░░░░▒░░░░░░▒░░░░░▒▒░░▒░░░░░░░░▒▒▒
▒░░░░█▀▀░█▀█░█▀█░█▀▄░█▀▄░▀█▀░█▀█░█▀█░▀█▀░█▀▀░█▀▀░░▒░▒
▒░▒░░█░░░█░█░█░█░█▀▄░█░█░░█░░█░█░█▀█░░█░░█▀▀░▀▀█░░░░▒
▒▒░░░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░▀░▀░▀░░▀░░▀▀▀░▀▀▀░░░░▒
▒░▒▒░░░░░░░░░▒░░░░░▒░░░█▀▄░█░█░░░░░░░░░░▒▒░░▒░░░░░░▒▒
▒░░░░░▒░░░░░▒░░░▒░▒░░░░█▀▄░░█░░░░░░░▒░░▒░░░░▒░░░▒░░░▒
▒▒░▒░░░░▒▒░░░░░░░░░░░░░▀▀░░░▀░░░░░░░░░░░░▒░░░░░░░░▒▒▒
▒░░░░░░░░░▒░░▀█▀░█▀▄░█▀█░█░█░█▀▀░█▀▀░█▀▀░░░░░░░▒░▒░░▒
▒▒░░░░░▒░░░░░░█░░█▀▄░█▀█░▀▄▀░█▀▀░▀▀█░▀▀█░░░░░▒░░░░░░▒
▒░░▒░░░░░░░░░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀▀▀░▀▀▀░░░░░░░░░░░▒▒
▒░▒░▒░░▒░▒░░░█▀▀░█▄█░█▀█░█░░░█░░░█▀▀░█░█░░░░░░░░▒░░▒▒
▒░░░░░░░░░░░░▀▀█░█░█░█▀█░█░░░█░░░█▀▀░░█░░░░░▒░░░░░▒▒▒
▒▒▒░░░░░▒░░░░▀▀▀░▀░▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░░▀░░░░░░░░░░░░░▒
▒░░░░░░░░░░░░░░░░░░▀▀▄░▄▀▄░▀▀▄░▀▀█░░░░░░░░▒░░░░░░▒░░▒
▒▒░░░▒░░░░▒░░░░░▒░░▄▀░░█/█░▄▀░░░▀▄░▒░░░░░░░░░░░▒░░▒░▒
▒▒▒▒░░░░▒░░░░░░░▒▒░▀▀▀░░▀░░▀▀▀░▀▀░░░░░░░░░░▒▒░░░░░░▒▒
▒▒▒░░▒░░░░░░░░░░▒░░░░░░░░░▒░░▒░░░░░▒░░░░░░░░░░▒░░░▒░▒
▃▕▊▕▟▉▒▗█▗▝▐▙▀▗▃▝▝▃▄▂▚▉▓▘▗▎▄▂▕▟▃▉▊▘▆▔▉▝▚▞▘▉▕▙▟▖▖▚▙▘▜▒
▖▛▌▖▐▋▗▗▔▎▞▇▖▛▟▒▔▇▅▊▆▛▀▀▓▘▚▂▕▆▉█▁▖▟▎▀▖▅▔▃▃▚▙▝▙▉░▀▎▛▄▇
▎▜▚▃▂▄▋▁▘█▐▖▝▔▊▀▗▄▗▔▛▀▂▜▌▛▀▓▔▃▊▀▝▃▃▀▅▍▟▝▖▍▔▓▁▜░▘▞█▊▙▆
▆▔▄▘▕▌▙▒▐▜▐▕▇▐░▞▝▄▎▞▞▀▔▜▆▜▕▊▇█▜▍▜▞▅░▋▞▂▛▙░▎▀▀▟▜▛▁▉▗▟▉
▅▍▖▌▖░▚▒▎▟▂▘▜▃▔▕▒▂▓▒▟▐▊▀▙▁▟▀▉▘▋▎▅▟▛▜▐▓▋▟░▌▗▌▐█▟▁█▐░▇▝
▘▄▔▁▜▝▎▀▝▇▜▌▙▇▉▉▔▟▖▁▅▓▀▎▂▎▔▀▇▚▔▟▜▆▟▗▁▍▗▜▓░▉▋▘░▕▊▐█▋▔▙
▙▔▚▁▋▋▀▆▐▟▝▐▊▒▋▞▂▕▇▚▄▛▂▒▃▎▅▛▗▅▕▐▘▎░▃▘▒▇▆▎▄▖▚▖▁▖▖▕▛░▙▖
▝▎▕▔▔▉▄▋▖▕▍▋▄▕▐▔▘▅▋▋▇▟▂▚▚░▓░▁▛█▟▉▛▓▞▂▗▇▖▌▕▁░█▒▂▀▕▋▋▚▊
▞▄▒▀▀▚▝▇▓▐▅▕▇▋▊▒▞▉▀▆▙▃▄▎▌░▆▖▜▛▙▙▟▊▗▝▂▔▅▕▃█▉█▔▒▚▓▛▛▗▓▜
▌▅▜▆▀▕▟▞▝▔▛▟▇▀▒▉▇▛▒▛▊▊▋▆▃▃▙▝▝▖▃▉▛▀▍▜▓▋▘▎▟▓▍▅▒▞▌▗▗▜▐▂▆
▝▝▄▚▓█▁▍▆▌▇▙▘▟▇▖░▔▛▀▒▇▗▆▁▄██▀▎▐▛▉▓▓▜▛▔▊▁▁▐▘▗▍▞▌▞▒▅▜▁▊
----------------------------------------------------------------------------------------------------

Coordinates
By Travess Smalley
Presented by Folia.app
*/

/// @title Coordinates
/// @notice https://coordinates.folia.app
/// @author @okwme
/// @dev ERC721A contract for Coordinates. External upgradeable metadata.

contract Coordinates is ERC721AQueryable, Ownable, ERC2981, ReentrancyGuard {
    bool public paused = false;
    bool public forceOpen = false;
    uint256 public constant MAX_SUPPLY = 139;
    uint256 public price = 0.24 ether;
    address public metadata;
    address public splitter;
    uint256 public premint = 1698778800; // Tue Oct 31 2023 19:00:00 GMT+0000 (8pm CEST Berlin, 4pm London, 11am NYC, 8am LA)
    uint256 public startdate = 1698865200; // Wed Nov 01 2023 19:00:00 GMT+0000 (8pm CEST Berlin, 7pm London, 2pm NYC, 11am LA)
    bytes32 public merkleRoot =
        0x7eb11619d1dd456844424b6c6f1be20ba3552298bb97a978724278ddebbd4474;

    uint256 public constant MAX_PER_PREMINT = 2;
    mapping(address => uint256) public preminted;

    event EthMoved(
        address indexed to,
        bool indexed success,
        bytes returnData,
        uint256 amount
    );

    constructor(
        address metadata_,
        address splitter_
    ) ERC721A("Coordinates", "CRD") {
        metadata = metadata_;
        splitter = splitter_; // splitter doesn't need to be checked because it's checked in _setDefaultRoyalty
        _setDefaultRoyalty(splitter, 750); // 7.5%
    }

    /// @dev Allows minting by sending directly to the contract.
    fallback() external payable {
        mint();
    }

    /// @dev Allows minting by sending directly to the contract.
    receive() external payable {
        mint();
    }

    /// @dev Overwrites the _startTokenId function from ERC721A so that the first token id is 1
    /// @return uint256 the id of the first token
    function _startTokenId()
        internal
        view
        virtual
        override(ERC721A)
        returns (uint256)
    {
        return 1;
    }

    /// @dev overwrites the tokenURI function from ERC721
    /// @param id the id of the Coordinates
    /// @return string the URI of the Coordinates
    function tokenURI(
        uint256 id
    ) public view override(ERC721A, IERC721A) returns (string memory) {
        return Metadata(metadata).getMetadata(id);
    }

    /// @dev check whether an address is allowed to mint using a merkle proof
    /// @param _wallet the address of the wallet
    /// @param _proof the merkle proof
    /// @return bool whether the address is allowed to mint
    function allowListed(
        address _wallet,
        bytes32[] calldata _proof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                _proof,
                merkleRoot,
                keccak256(abi.encodePacked(_wallet))
            );
    }

    /// @dev mint tokens with merkle proof
    /// @param quantity the quantity of tokens to mint
    /// @param _proof the merkle proof
    function mintAllowList(
        uint256 quantity,
        bytes32[] calldata _proof
    ) external payable {
        require(
            allowListed(msg.sender, _proof),
            "You are not on the allowlist"
        );
        require(!paused && block.timestamp >= premint, "Premint not started");
        require(
            preminted[msg.sender] + quantity <= MAX_PER_PREMINT,
            "You can only mint 2 per premint"
        );
        preminted[msg.sender] += quantity;
        internalMint(msg.sender, quantity);
    }

    /// @dev mint token with default settings
    function mint() public payable {
        mint(msg.sender, 1);
    }

    /// @dev mint tokens with recipient as parameter
    /// @param recipient the recipient of tokens to mint
    function mint(address recipient) public payable {
        mint(recipient, 1);
    }

    /// @dev mint tokens with quantity as parameter
    /// @param quantity the quantity of tokens to mint
    function mint(uint256 quantity) public payable {
        mint(msg.sender, quantity);
    }

    /// @dev mint tokens with rcipient and quantity as parameters
    /// @param recipient the recipient of the Coordinates
    /// @param quantity the quantity of tokens to mint
    function mint(address recipient, uint256 quantity) public payable {
        require(
            (!paused && block.timestamp >= startdate) || forceOpen,
            "PAUSED"
        );
        internalMint(recipient, quantity);
    }

    /// @dev mint tokens with rcipient and quantity as parameters
    /// @param recipient the recipient of the Coordinates
    /// @param quantity the quantity of tokens to mint
    function internalMint(
        address recipient,
        uint256 quantity
    ) internal nonReentrant {
        require(msg.value >= price * quantity, "WRONG PRICE");
        require(quantity <= 5, "CAN'T MINT MORE THAN 5 AT A TIME");
        if (totalSupply() + quantity > MAX_SUPPLY) {
            quantity = MAX_SUPPLY - totalSupply(); // This will throw an error if the amount is negative
            if (quantity == 0) {
                revert("MAX SUPPLY REACHED");
            }
        }
        uint256 payment = quantity * price;
        (bool sent, bytes memory data) = splitter.call{value: payment}("");
        emit EthMoved(splitter, sent, data, payment);

        _safeMint(recipient, quantity);
        // call this after _safeMint so totalSupply updates before a re-entry mintcould be called
        // UPDATE: re-entry no longer possible with reentrancy guard
        if (payment < msg.value) {
            (sent, data) = msg.sender.call{value: msg.value - payment}("");
            emit EthMoved(msg.sender, sent, data, msg.value - payment);
        }
    }

    /// @dev only the owner can mint without paying
    /// @param recipient the recipient of the Coordinates
    /// @param quantity the quantity of tokens to mint
    function adminMint(
        address recipient,
        uint256 quantity
    ) public payable onlyOwner {
        (bool sent, bytes memory data) = splitter.call{value: msg.value}("");
        emit EthMoved(splitter, sent, data, msg.value);
        _safeMint(recipient, quantity);
    }

    /// @dev set the metadata address as called by the owner
    /// @param metadata_ the address of the metadata contract
    function setMetadata(address metadata_) public onlyOwner {
        require(metadata_ != address(0), "NO ZERO ADDRESS");
        metadata = metadata_;
    }

    /// @dev only the owner can set the splitter address
    /// @param splitter_ the address of the splitter
    function setSplitter(address splitter_) public onlyOwner {
        require(splitter_ != address(0), "NO ZERO ADDRESS");
        splitter = splitter_;
    }

    /// @dev only the owner can set the price
    /// @param price_ the price of the Coordinates
    function setPrice(uint256 price_) public onlyOwner {
        price = price_;
    }

    /// @dev only the owner can set the contract paused
    /// @param paused_ whether the contract is paused
    function setPause(bool paused_) public onlyOwner {
        paused = paused_;
    }

    /// @dev only the owner can set the forceOpen boolean
    /// @param forceOpen_ whether the contract is forceOpen
    function setForceOpen(bool forceOpen_) public onlyOwner {
        forceOpen = forceOpen_;
    }

    /// @dev only the owner can set the startdate
    /// @param startdate_ the startdate of the mint event
    function setStartdate(uint256 startdate_) public onlyOwner {
        startdate = startdate_;
    }

    /// @dev only the owner can set the premint date
    /// @param premint_ the premint date of the mint event
    function setPremint(uint256 premint_) public onlyOwner {
        premint = premint_;
    }

    /// @dev only the owner can set the merkle root
    /// @param merkleRoot_ the merkle root of the premint event
    function setMerkleRoot(bytes32 merkleRoot_) public onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /// @dev set the royalty percentage as called by the owner
    /// @param royaltyReceiver the address of the royalty receiver
    /// @param royaltyPercentage the percentage of the royalty
    function setRoyaltyPercentage(
        address royaltyReceiver,
        uint96 royaltyPercentage
    ) public onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, royaltyPercentage);
    }

    /// @dev if mint fails to send eth to splitter, admin can recover
    // This should not be necessary but Berlin hardfork broke split before so this
    // is extra precaution.
    function recoverUnsuccessfulMintPayment(
        address payable _to
    ) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        emit EthMoved(_to, sent, data, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    /// @dev set the royalty percentage as called by the owner
    /// @param interfaceId the interface id
    /// @return bool whether the interface is supported
    /// @notice ERC2981, ERC721A, IERC721A are overridden to support multiple interfaces
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721A, IERC721A) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
