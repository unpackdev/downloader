// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

/**
 *  @title Meta DAO NFT
 *
 *  @notice This implements the contract for the Meta DAO NFT.
 *  Contract can be paused by disabling public mints and creating a bogus merkle
 *  root tree for the whitelist. Funds from sales can be withdrawn any time by
 *  anyone and will withdrawn to founders + artist. All founders on the contract
 *  share a 90% split and can be removed. The artist gets a 10% split and
 *  can never be removed.
 */

contract MetaDaoNft is ERC721A, Ownable, AccessControlEnumerable {
    /// @dev The price of a single mint in Ether
    uint256 public constant PRICE = 0.04 ether;

    /// @dev Hardcoded cap on the maximum number of mints.
    uint256 public constant MAX_MINTS = 4444;

    /// @dev A role for people who are project founders.
    bytes32 public constant FOUNDER_ROLE = keccak256('FOUNDER_ROLE');

    /// @dev A role for the artist.
    bytes32 public constant ARTIST_ROLE = keccak256('ARTIST_ROLE');

    /// @dev Holds the value of the baseURI for token generation
    string private _baseTokenURI;

    /// @dev A mapping of addresses to claimable mints
    mapping(address => uint256) public staffAllocations;

    /**
     * @dev Indicates if public minting is opened. If true, addresses not on the
     * whitelist can mint tokens. If false, the address must be on the whitelist
     * to mint.
     */
    bool public isPublicMintingAllowed = false;

    /**
     *  @dev A merkle tree root for the whitelist. The merkle tree is generated
     * off-chain to save gas, and the root is stored on contract for verification.
     */
    bytes32 private _whitelistMerkleRoot;

    /// @dev An event emitted when the mint was successful.
    event SuccessfulMint(uint256 numMints, address recipient);

    /// @dev An event emitted when funds have been received.
    event ReceivedFunds(uint256 msgValue);

    /// @dev Gates functions that should only be called by the contract admins.
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Must be an admin.');
        _; // Executes the rest of the modified function
    }

    /// @dev Gates functions that should only be called by people who have claimable free mints
    modifier onlyWithAllocation() {
        uint256 claimableMints = staffAllocations[_msgSender()];
        require(claimableMints > 0, 'Must have claimable mints');
        _; // Executes the rest of the modified function
    }

    /**
     *  @dev Gates functions that should only be called if there are mints left
     *
     * @param numMints The number of mints attempting to be minted.
     */
    modifier onlyWithMintsLeft(uint256 numMints) {
        require(totalSupply() != MAX_MINTS, 'Soldout!');
        require(totalSupply() + numMints <= MAX_MINTS, 'Not enough mints left.');
        _; // Executes the rest of the modified function
    }

    /**
     * @notice Deploys the contract, sets the baseTokenURI, sets the the max
     * mints, roles for founders and disables public minting.
     *
     * @param founders The addresses of founders to be granted founder role.
     * @param artist The address of the artist to be granted artist role.
     * @param staff The address of the staff members who will be granted 5 free mints
     * @param newBaseURI The base URI for the artwork generated for this contract
     */
    constructor(
        address[] memory founders,
        address artist,
        address[] memory staff,
        string memory newBaseURI
    ) ERC721A('Meta DAO NFT', 'METADAONFT') {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _baseTokenURI = newBaseURI;

        for (uint256 i = 0; i < staff.length; i++) {
            address staffAddress = staff[i];
            staffAllocations[staffAddress] = 5; // 5 claimable mints per staff member
        }

        for (uint256 i = 0; i < founders.length; i++) {
            address founderAddress = founders[i];
            staffAllocations[founderAddress] = 20; // 20 claimable mints per founder
        }

        staffAllocations[artist] = 20; // 20 claimable mints for artist

        _setupRole(ARTIST_ROLE, artist);

        for (uint256 i = 0; i < founders.length; i++) {
            _setupRole(FOUNDER_ROLE, founders[i]);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Admin-only function to set the whitelist with a merkle root that
     * is generated off-chain.
     *
     * @param whitelistMerkleRoot An off-chain-generated merkle root for a list
     * of addresses that should be whitelisted. For more info on generating
     * merkle roots off chain for this contract, see:
     * https://dev.to/0xmojo7/merkle-tree-solidity-sc-validation-568m
     */

    function updateWhitelist(bytes32 whitelistMerkleRoot) public onlyAdmin {
        _whitelistMerkleRoot = whitelistMerkleRoot;
    }

    /**
     * @notice Verifies the whitelist status of a recipient address.
     * @dev To generate the parameters for this function, see:
     * https://dev.to/0xmojo7/merkle-tree-solidity-sc-validation-568m
     * https://github.com/miguelmota/merkletreejs/
     *
     * @param recipient The address to check.
     * @param _proof Array of hex values denoting the kekkack hashes of leaves
     * in the merkle root tree leading to verified address.
     * @param _positions Array of string values of 'left' or 'right' denoting the
     * position of the address in the corresponding _proof array to navigate to
     * the verifiable address.
     *
     * @return True if the address is whitelisted, false otherwise.
     */
    function verifyWhitelist(
        address recipient,
        bytes32[] memory _proof,
        uint256[] memory _positions
    ) public view returns (bool) {
        if (_proof.length == 0 || _positions.length == 0) {
            return false;
        } else {
            bytes32 _leaf = keccak256(abi.encodePacked(recipient));
            return MerkleProof.verify(_whitelistMerkleRoot, _leaf, _proof, _positions);
        }
    }

    /**
     * @notice Mints new tokens for the recipient. Admins can mint any number of
     * free tokens per transaction, for use in marketing purposes or to give away.
     * During whitelist, the sender must be whitelisted and provide a proof and
     * position in the Merkle Tree. During whitelist, there's a max of 2 mints
     * per tx. During public sales, there's a max of 5 mints per tx. The value
     * of the transaction must be at least the mint price multiplied by the
     * number of mints being minted.
     *
     * @dev To generate the _proof and _positions parameters for this function, see:
     * https://dev.to/0xmojo7/merkle-tree-solidity-sc-validation-568m
     * https://github.com/miguelmota/merkletreejs/
     *
     * @param recipient The address to receive the newly minted tokens
     * @param numMints The number of mints to mint
     * @param _proof Array of hex values denoting the kekkack hashes of leaves
     * in the merkle root tree leading to verified address. Used to verify the
     * recipient is whitelisted, if minting during whitelist period.
     * @param _positions Array of string values of 'left' or 'right' denoting the
     * position of the address in the corresponding _proof array to navigate to
     * the verifiable address. Used to verify the is whitelisted, if minting
     * during whitelist period.
     */
    function mint(
        address recipient,
        uint8 numMints,
        bytes32[] memory _proof,
        uint256[] memory _positions
    ) public payable onlyWithMintsLeft(numMints) {
        require(numMints > 0, 'Must provide an amount to mint.');

        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(msg.value >= PRICE * numMints, 'Value below price');

            if (isPublicMintingAllowed) {
                require(numMints <= 5, 'Can mint a max of 5 during public sale');
            } else {
                require(verifyWhitelist(_msgSender(), _proof, _positions), 'Not on whitelist.');
                require(numMints <= 2, 'Can mint a max of 2 during presale');
            }
        }

        _safeMint(recipient, numMints);
        emit SuccessfulMint(numMints, recipient);
    }

    /**
     * @notice Mints claimable tokens for staff members, artist, and founders.
     *
     * @dev This function pulls the allocations from the staffAllocations map,
     * and mints the appropriate number of mints for the address claiming, then
     * marks the mints as claimed by setting the value in the map to 0.
     */
    function staffMint() public onlyWithAllocation onlyWithMintsLeft(staffAllocations[_msgSender()]) {
        _safeMint(_msgSender(), staffAllocations[_msgSender()]);
        staffAllocations[_msgSender()] = 0;
        emit SuccessfulMint(staffAllocations[_msgSender()], _msgSender());
    }

    /**
     * @notice Enables public minting. When enabled, addresses that are not on
     * the whitelist are able to mint.
     */
    function allowPublicMinting() public onlyAdmin {
        isPublicMintingAllowed = true;
    }

    /**
     * @notice Enables public minting. When enabled, addresses that are not on
     * the whitelist are able to mint.
     */
    function disallowPublicMinting() public onlyAdmin {
        isPublicMintingAllowed = false;
    }

    /**
     * @dev All interfaces need to support `supportsInterface`. This function
     * checks if the provided interface ID is supported.
     *
     * @param interfaceId The interface ID to check.
     *
     * @return True if the interface is supported (AccessControlEnumerable,
     * ERC721, ERC721Enumerable), false otherwise.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Withdraws all funds from contract address. Founders get 90%,
     * artist gets remaining 10%.
     *
     */
    function withdrawAll() public {
        uint256 balance = address(this).balance;
        uint256 founderCount = getRoleMemberCount(FOUNDER_ROLE);
        require(balance > 0, 'Nothing to withdraw.');

        // 90% split between founders
        uint256 founderBalance = (balance * 9) / 10;
        for (uint256 i = 0; i < founderCount; i++) {
            address member = getRoleMember(FOUNDER_ROLE, i);
            _withdraw(member, founderBalance / founderCount);
        }

        uint256 artistBalance = address(this).balance; // Should be the remaining 10%.
        address artist = getRoleMember(ARTIST_ROLE, 0);
        _withdraw(artist, artistBalance);
    }

    /**
     * @dev Encapsulates the logic of withdrawing funds from the contract to
     * a given address.
     *
     * @param recipient The address to receive the funds.
     * @param amount The amount of funds to be withdrawn.
     */
    function _withdraw(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Transfer failed.');
    }
}
