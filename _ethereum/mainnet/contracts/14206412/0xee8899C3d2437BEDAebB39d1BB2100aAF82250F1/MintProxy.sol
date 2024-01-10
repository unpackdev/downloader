// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./AccessControl.sol";
import "./ECDSA.sol";

contract MintProxy is AccessControl
{
    /**
     * Signer.
     * @dev this is the address used to verify restricted mint addresses.
     */
    address private _signer;

    /**
     * Target.
     * @dev address of the contract with the real mint function.
     */
    address public target = 0xb853Ad67032738ffbcAc61a856CA7c44AE36d10f;

    /**
     * Minted.
     * @dev store quantity minted for each address using keccak256 on mint version + address.
     */
    mapping(bytes32 => uint256) public minted;

    /**
     * MintVersion.
     * @dev by versioning the mint, we can effectively clear minted data to resue the contract.
     */
    uint256 public mintVersion = 1;

    /**
     * MintTypes.
     * @dev struct for storing mint types... public or restricted.
     */
    enum mintTypes { publicMint , restrictedMint }

    /**
     * MintTypes.
     * @dev public variable to store the current mint type.
     */
    mintTypes public mintType;

    /**
     * MintPrice.
     * @dev price of the mint in wei.
     */
    uint256 public mintPrice;

    /**
     * MaxMint.
     * @dev maximum amount someone can mint in the current version. Does not affect
     * restricted mint or admin mint.
     */
    uint256 public mintMax;

    /**
     * MintActive.
     * @dev whether or not the mint is currently active. Does not affect admin mint.
     */
    bool public mintActive = false;

    /**
     * Constructor.
     */
    constructor()
    {
        // assign contract creator to _signer.
        _signer = _msgSender();
        // give contract creator admin role.
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * Minted event
     */
    event Minted(
        address minter,
        uint256 quantity
    );

    /**
     * Mint updated event
     */
    event MintUpdated(
        address target,
        uint256 mintVersion,
        mintTypes mintType,
        uint256 mintPrice,
        uint256 mintMax,
        bool mintActive
    );

    /**
     * Contract withdrawn
     */
    event ContractWithdrawn(
        address to,
        uint256 amount
    );

    /**
     * Public mint.
     * check that mintType = publicMint
     * check that mintActive = true
     * check that minted + quantity <= maxMint
     *
     * @param quantity uint256
     */
    function publicMint(uint256 quantity)
    external
    payable
    correctMintType(mintTypes.publicMint)
    mintIsActive
    belowMax(quantity)
    {
        _mint(_msgSender(), quantity, mintPrice);
    }

    /**
     * Restricted mint.
     * check that mintType = restrictedMint
     * check that mintActive = true
     * check that quantity <= assignedQuantity
     * check that signature is valid
     *
     * @param signature bytes memory
     * @param assignedQuantity uint256
     * @param quantity uint256
     */
    function restrictedMint(bytes memory signature, uint256 assignedQuantity, uint256 quantity)
    external
    payable
    correctMintType(mintTypes.restrictedMint)
    mintIsActive
    belowAssigned(assignedQuantity, quantity)
    validSignature(signature, assignedQuantity)
    {
        _mint(_msgSender(), quantity, mintPrice);
    }

    /**
     * Admin mint.
     * allow admins to mint unrestricted
     *
     * @param to address
     * @param quantity uint256
     */
    function adminMint(address to, uint256 quantity) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _mint(to, quantity, 0);
    }

    /**
     * Mint.
     * internal mint function
     * check that msg.value == quantity * mintPrice
     *
     * @param to address
     * @param quantity uint256
     * @param price uint256
     */
    function _mint(address to, uint256 quantity, uint256 price)
    internal
    correctPrice(quantity, price)
    {
        adminMintable(target).adminMint(to, quantity);
        minted[_getMintedKey(to)] += quantity;
        emit Minted(to, quantity);
    }

    /**
     * Get minted by address.
     * return mint quantity for address in current mint version
     *
     * @param _address address
     * @return uint256
     */
    function mintedByAddress(address _address) public view returns(uint256)
    {
        return minted[_getMintedKey(_address)];
    }

    /**
    * New mint version.
    * This increments the mint version so that we can effectively
    * remove all previous mints. This will allow us to use this
    * contract to handle different self minting events such as
    * whitelist minting, presale minting, airdrops, etc.
    */
    function newMintVersion() external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintVersion++;
        _fireMintUpdatedEvent();
    }

    /**
     * Set mint type.
     *
     * @param _mintType uint
     */
    function setMintType(uint _mintType) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintType = mintTypes(_mintType);
        _fireMintUpdatedEvent();
    }

    /**
     * Set mint price.
     *
     * @param _mintPrice uint256
     */
    function setMintPrice(uint256 _mintPrice) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintPrice = _mintPrice;
        _fireMintUpdatedEvent();
    }

    /**
     * Set max mint.
     *
     * @param _mintMax uint256
     */
    function setMintMax(uint256 _mintMax) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintMax = _mintMax;
        _fireMintUpdatedEvent();
    }

    /**
     * Activate mint.
     */
    function activateMint() external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintActive = true;
        _fireMintUpdatedEvent();
    }

    /**
     * Deactivate mint.
     */
    function deactivateMint() external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        mintActive = false;
        _fireMintUpdatedEvent();
    }

    /**
     * Set target.
     *
     * @param _target address
     */
    function setTarget(address _target) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        target = _target;
        _fireMintUpdatedEvent();
    }

    /**
     * Fire MintUpdated event
     */
    function _fireMintUpdatedEvent() internal
    {
        emit MintUpdated(target, mintVersion, mintType, mintPrice, mintMax, mintActive);
    }

    /**
     * Get key for mint mapping.
     * return keccak256 on mintVersion and _address
     *
     * @param _address address
     */
    function _getMintedKey(address _address) internal view returns(bytes32)
    {
        return keccak256(abi.encodePacked(mintVersion, _address));
    }

    /**
     * Update signer.
     *
     * @param signer address
     */
    function updateSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _signer = signer;
    }

    /**
     * Withdraw.
     *
     * @param to address
     */
    function withdraw(address to) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 amount = address(this).balance;
        payable(to).transfer(amount);
        emit ContractWithdrawn(to, amount);
    }

    /**
     * Change target owner.
     *
     * @param newOwner address
     */
    function changeTargetOwner(address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE)
    {
        adminMintable(target).transferOwnership(newOwner);
    }

    /**
     * correctMintType modifier.
     *
     * @param _mintType mintTypes
     */
    modifier correctMintType(mintTypes _mintType)
    {
        require(mintType == _mintType, 'INCORRECT MINT TYPE');
        _;
    }

    /**
     * mintIsActive modifier.
     */
    modifier mintIsActive()
    {
        require(mintActive, 'MINT IS NOT ACTIVE');
        _;
    }

    /**
     * belowMax modifier.
     *
     * @param quantity uint256
     */
    modifier belowMax(uint256 quantity)
    {
        require(minted[_getMintedKey(_msgSender())] + quantity <= mintMax, 'EXCEEDS MAX MINT');
        _;
    }

    /**
     * belowAssigned modifier.
     *
     * @param assignedQuantity uint256
     * @param quantity uint256
     */
    modifier belowAssigned(uint256 assignedQuantity, uint256 quantity)
    {
        require(minted[_getMintedKey(_msgSender())] + quantity <= assignedQuantity, 'EXCEEDS ASSIGNED QUANTITY');
        _;
    }

    /**
     * validSignature modifier.
     *
     * @param signature bytes memory
     * @param assignedQuantity uint256
     */
    modifier validSignature(bytes memory signature, uint256 assignedQuantity)
    {
        bytes32 messageHash = sha256(abi.encode(_msgSender(), assignedQuantity, mintVersion));
        require(ECDSA.recover(messageHash, signature) == _signer, 'INVALID SIGNATURE');
        _;
    }

    /**
     * correctPrice modifier.
     *
     * @param quantity uint256
     * @param price uint256
     */
    modifier correctPrice(uint256 quantity, uint256 price)
    {
        require(msg.value == quantity * price, 'INCORRECT VALUE');
        _;
    }
}

interface adminMintable
{
    function adminMint(address to, uint256 quantity) external;
    function transferOwnership(address newOwner) external;
}
