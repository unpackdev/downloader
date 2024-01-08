////////////////////////////////////////////////
////////////////////////////////////////////////
// ███╗░░██╗██╗███████╗██╗░░██╗███████╗██╗░░░██╗
// ████╗░██║██║██╔════╝██║░██╔╝██╔════╝╚██╗░██╔╝
// ██╔██╗██║██║█████╗░░█████═╝░█████╗░░░╚████╔╝░
// ██║╚████║██║██╔══╝░░██╔═██╗░██╔══╝░░░░╚██╔╝░░
// ██║░╚███║██║██║░░░░░██║░╚██╗███████╗░░░██║░░░
// ╚═╝░░╚══╝╚═╝╚═╝░░░░░╚═╝░░╚═╝╚══════╝░░░╚═╝░░░
// https://nifkey.xyz
////////////////////////////////////////////////
////////////////////////////////////////////////

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./Counters.sol";
import "./Voucher.sol";

contract NifkeyEIP712 {
    function verify(NFKVoucher calldata voucher)
        external
        view
        returns (address)
    {}
}

contract Nifkey is ERC721, Ownable {
    using Counters for Counters.Counter;
    NifkeyEIP712 private eip712;

    uint256 public constant MAX_MINT_PRICE = 0.02 ether;
    string public baseURI = "https://nifkey.xyz/api/token/";
    uint256 public maxAssociatedWallets = 10;

    // _isMinter maps an address to whether the address has the right to mint vouchers redeemable for Nifkeys
    mapping(address => bool) private _isMinter;

    // _isAssociatedWallet maps a tokenId to a mapping that maps and address to a struct containing the index at which
    // the address appears in the _associatedWalletsForTokenId[tokenId] list (if the tokenId and address are associated at all)
    // needs to be updated when:
    // 1. a new nifkey is minted for the first time
    // 2. an associated wallet is added to a nifkey
    // 3. an associated wallet is removed from a nifkey
    // 4. a nifkey is burned
    mapping(uint256 => mapping(address => IndexOfAssociatedWallet))
        private _isAssociatedWallet;

    // _associatedWalletsForTokenId maps a tokenId to a list of addresses that are "associated wallets" for the nifkey
    // needs to be updated when:
    // 1. a new nifkey is minted for the first time
    // 2. an associated wallet is added to a nifkey
    // 3. an associated wallet is removed from a nifkey
    // 4. a nifkey is burned
    mapping(uint256 => address[]) private _associatedWalletsForTokenId;

    // tokenIdForWallet maps an address to the tokenId of the nifkey it's associated with (if any)
    // needs to be updated when
    // 1. a new nifkey is minted for the first time
    // 2. an associated wallet is added to a nifkey
    // 3. an associated wallet is removed from a nifkey
    // 4. a nifkey is burned
    mapping(address => uint256) public tokenIdForWallet;

    // twitterDataForTokenId maps a tokenId to a struct containing twitter data for the nifkey
    // needs to be updated when
    // 1. a twitter user mints a nifkey for the first time
    // 2. a twitter user re-mints their nifkey
    // 3. a nifkey is burned
    mapping(uint256 => TwitterDataParams) public twitterDataForTokenId;

    // tokenIdForTwitterUsername stores the mapping from a twitterUsername to a tokenId
    // needs to be updated when
    // 1. a twitter user mints a nifkey for the first time
    // 2. a twitter user mints a nifkey with a twitter username that previously belonged to a different nifkey
    // 3. a twitter user re-mints a nifkey after changing their twitterusername
    // 4. a nifkey is burned
    mapping(string => uint256) public tokenIdForTwitterUsername;

    // a nonce for each tokenId that is checked when a nifkey voucher is redeemed for a nifkey
    mapping(uint256 => Counters.Counter) public nonceForTokenId;

    constructor(address minter, address EIP712address) ERC721("Nifkey", "NFK") {
        _isMinter[minter] = true;
        eip712 = NifkeyEIP712(EIP712address);
    }

    event Minted(address indexed _wallet, uint256 indexed _tokenId);
    event WalletAdded(address indexed _wallet, uint256 indexed _tokenId);
    event WalletRemoved(address indexed _wallet, uint256 indexed _tokenId);
    event Burned(address indexed _wallet, uint256 indexed _tokenId);
    event BurnedAndTransferred(
        address indexed _oldOwner,
        address indexed _newOwner,
        uint256 indexed _tokenId
    );
    event OwnerTransferred(
        address indexed _oldOwner,
        address indexed _newOwner,
        uint256 indexed _tokenId
    );
    event TwitterDataUpdated(
        uint256 indexed _tokenId,
        uint256 _numFollowers,
        bool _isVerified
    );
    event UsernameUpdated(
        uint256 indexed _oldTokenId,
        uint256 indexed _newTokenId,
        string _twitterUsername
    );

    struct TwitterDataParams {
        uint64 numFollowers;
        uint64 createdAt;
        uint64 twitterId;
        bool isVerified;
        bool isValue;
        string twitterUsername;
    }

    struct IndexOfAssociatedWallet {
        uint32 index;
        bool isAssociated;
    }

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function associatedWalletsForTokenId(uint256 tokenId)
        external
        view
        returns (address[] memory)
    {
        return _associatedWalletsForTokenId[tokenId];
    }

    function updateBaseURI(string calldata uri) external onlyOwner {
        baseURI = uri;
    }

    function updateEIP712Contract(address EIP712Address) external onlyOwner {
        eip712 = NifkeyEIP712(EIP712Address);
    }

    function updateMaxAssociatedWallets(uint256 _maxAssociatedWallets)
        external
        onlyOwner
    {
        maxAssociatedWallets = _maxAssociatedWallets;
    }

    function addMinter(address minter) external onlyOwner {
        _isMinter[minter] = true;
    }

    function removeMinter(address minter) external onlyOwner {
        delete _isMinter[minter];
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    function burn(uint256 tokenId) external {
        require(
            _exists(tokenId) && tokenIdForWallet[msg.sender] == tokenId,
            "NFK: Not an associated wallet"
        );
        _delete(tokenId);
        _burn(tokenId);
        emit Burned(msg.sender, tokenId);
    }

    /// @notice Redeems an NFKVoucher for an actual NFK, creating it in the process.
    /// @param voucher A signed NFKVoucher that describes the NFK to be redeemed.
    function redeem(NFKVoucher calldata voucher) external payable {
        _verify(voucher);
        uint256 tokenId = uint256(voucher.twitterId);
        if (_intermediateSteps(tokenId, voucher)) return;

        require(
            msg.value >= voucher.mintPrice &&
                MAX_MINT_PRICE >= voucher.mintPrice,
            "NFK: Must pay mint price"
        );
        // if tokenId already exists
        if (_exists(tokenId)) {
            address owner = address(ownerOf(tokenId));
            _delete(tokenId);
            _transfer(owner, msg.sender, tokenId);
            emit BurnedAndTransferred(owner, msg.sender, tokenId);
        } else {
            _mint(msg.sender, tokenId);
            emit Minted(msg.sender, tokenId);
        }
        _addWallet(tokenId, voucher);
        nonceForTokenId[tokenId].increment();
    }

    function _delete(uint256 tokenId) internal {
        // delete all existing associated wallets from tokenIdForWallet and _isAssociatedWallet
        for (
            uint256 i = 0;
            i < _associatedWalletsForTokenId[tokenId].length;
            i++
        ) {
            delete tokenIdForWallet[_associatedWalletsForTokenId[tokenId][i]];
            delete _isAssociatedWallet[tokenId][
                _associatedWalletsForTokenId[tokenId][i]
            ];
        }
        // delete _associatedWalletsForTokenId
        delete _associatedWalletsForTokenId[tokenId];

        // delete mapping from twitterUsername to tokenId
        delete tokenIdForTwitterUsername[
            twitterDataForTokenId[tokenId].twitterUsername
        ];

        // delete twitter data associated with tokenId
        delete twitterDataForTokenId[tokenId];
    }

    function addWallet(NFKVoucher calldata voucher) external {
        _verify(voucher);
        uint256 tokenId = uint256(voucher.twitterId);
        require(_exists(tokenId), "NFK: Nifkey does not exist");
        if (_intermediateSteps(tokenId, voucher)) return;
        require(
            _associatedWalletsForTokenId[tokenId].length < maxAssociatedWallets,
            "NFK: Max associated wallets"
        );

        // delete mapping from twitterUsername to tokenId. it will be re-added or updated in _addWallet() below
        delete tokenIdForTwitterUsername[
            twitterDataForTokenId[tokenId].twitterUsername
        ];

        _addWallet(tokenId, voucher);
        nonceForTokenId[tokenId].increment();
        emit WalletAdded(msg.sender, tokenId);
    }

    function _intermediateSteps(uint256 tokenId, NFKVoucher calldata voucher)
        internal
        returns (bool)
    {
        require(
            voucher.nonce > nonceForTokenId[tokenId].current(),
            "NFK: Recycled voucher"
        );
        // If redeemer address is already an associated wallet of tokenId, then just refresh twitter data
        if (tokenIdForWallet[msg.sender] == tokenId) {
            _refresh(tokenId, voucher);
            return true;
        }
        require(tokenIdForWallet[msg.sender] == 0, "NFK: Already owner");
        return false;
    }

    function _addWallet(uint256 tokenId, NFKVoucher calldata voucher) internal {
        tokenIdForWallet[msg.sender] = tokenId;
        uint32 indexOf = uint32(_associatedWalletsForTokenId[tokenId].length);
        _associatedWalletsForTokenId[tokenId].push(msg.sender);
        _isAssociatedWallet[tokenId][msg.sender] = IndexOfAssociatedWallet(
            indexOf,
            true
        );

        _updateTwitterUsername(tokenId, voucher.twitterUsername);

        // For the current tokenId, update (or create) the twitterDataForTokenId struct
        twitterDataForTokenId[tokenId] = TwitterDataParams(
            uint64(voucher.numFollowers),
            uint64(voucher.createdAt),
            uint64(voucher.twitterId),
            voucher.isVerified,
            true,
            voucher.twitterUsername
        );

        emit TwitterDataUpdated(
            tokenId,
            voucher.numFollowers,
            voucher.isVerified
        );
    }

    function _refresh(uint256 tokenId, NFKVoucher calldata voucher) internal {
        twitterDataForTokenId[tokenId].numFollowers = uint64(
            voucher.numFollowers
        );
        twitterDataForTokenId[tokenId].isVerified = voucher.isVerified;
        if (
            keccak256(
                abi.encodePacked(
                    (twitterDataForTokenId[tokenId].twitterUsername)
                )
            ) != keccak256(abi.encodePacked((voucher.twitterUsername)))
        ) {
            // Username has been updated, so delete the mapping from the current username to tokenId
            delete tokenIdForTwitterUsername[
                twitterDataForTokenId[tokenId].twitterUsername
            ];

            _updateTwitterUsername(tokenId, voucher.twitterUsername);

            // For the current tokenId, update the twitterUsername field in the twitterDataForTokenId struct
            twitterDataForTokenId[tokenId].twitterUsername = voucher
                .twitterUsername;
        }

        nonceForTokenId[tokenId].increment();
        emit TwitterDataUpdated(
            tokenId,
            voucher.numFollowers,
            voucher.isVerified
        );
    }

    function _updateTwitterUsername(
        uint256 tokenId,
        string calldata newTwitterUsername
    ) internal {
        // It's possible that the new username was mapped to another tokenId
        // For that tokenId, delete the twitterUsername field in the twitterDataForTokenId struct
        delete twitterDataForTokenId[
            tokenIdForTwitterUsername[newTwitterUsername]
        ].twitterUsername;

        emit UsernameUpdated(
            tokenIdForTwitterUsername[newTwitterUsername],
            tokenId,
            newTwitterUsername
        );

        // Map the new username to the current tokenId
        tokenIdForTwitterUsername[newTwitterUsername] = tokenId;
    }

    function removeWallet(address toRemove) external {
        // Get tokenId of msg sender
        uint256 tokenId = tokenIdForWallet[msg.sender];

        // If msg sender doesn't own a Nifkey, they have no business calling removeWallet
        require(_exists(tokenId), "NFK: Doesn't own Nifkey");

        // Make sure that address being deleted is not the Nifkey owner
        require(toRemove != ownerOf(tokenId), "NFK: Cant remove owner");

        // Make sure the address being removed is an associated wallet for tokenId
        require(
            tokenIdForWallet[toRemove] == tokenId,
            "NFK: Not an associated wallet"
        );

        // Get last address in associatedWallets array
        address last = _associatedWalletsForTokenId[tokenId][
            _associatedWalletsForTokenId[tokenId].length - 1
        ];

        if (last != toRemove) {
            // Grab index of toRemove
            uint32 indexToRemove = _isAssociatedWallet[tokenId][toRemove].index;
            // Move last to index of toRemove
            _associatedWalletsForTokenId[tokenId][indexToRemove] = last;
            // Update index of last
            _isAssociatedWallet[tokenId][last].index = indexToRemove;
        }
        // Remove the last element from the array
        _associatedWalletsForTokenId[tokenId].pop();
        // Delete toRemove from _isAssociatedWallet[tokenId]
        delete _isAssociatedWallet[tokenId][toRemove];
        //  Delete toRemove from tokenIdForWallet
        delete tokenIdForWallet[toRemove];
        emit WalletRemoved(toRemove, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            tokenIdForWallet[to] == tokenId &&
                tokenIdForWallet[msg.sender] == tokenId,
            "NFK: not an associated wallet"
        );
        _safeTransfer(from, to, tokenId, _data);
        emit OwnerTransferred(from, to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {}

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {}

    /// @notice Verifies the signature for a given NFKVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFKs.
    /// @param voucher An NFTVoucher describing an unminted NFK.
    function _verify(NFKVoucher calldata voucher) internal view {
        // make sure that the signer is authorized to mint NFTs
        require(_isMinter[eip712.verify(voucher)] == true, "NFK: Sig invalid");

        // make sure that the redeemer is calling from the right address
        require(
            voucher.redeemerAddress == msg.sender,
            "NFK: Invalid redeemer address"
        );
    }
}
