// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*                                                                            .
 *                                                                            =:
 *                                                                           .=-
 *                                                                           -==
 *                                                                          :====
 *                                                                         :======
 *                                                                       :=========-.
 *                      .........                                ...::-================-::..
 *                .:-===============--:.                      .:::---====================--:::.
 *             :=========-:.          ..::::.                          .:-==========:.
 *          .-=======-:        .::-----------=-------------------::.       -======:
 *         -=======:        .-=======================================-.     -====.
 *       :=======-        .=============================================.    ===.
 *      :=======:        .=======================.=======================.   :==
 *     :=======:         ========================.========================    =:
 *    .=======-          ========================.========================    .
 *    -=======           ========================.========================
 *   .=======-           ========================.========================
 *   -=======.           ======================== ========================
 *   ========            ======================== -=======================
 *   ========            =======================: .=======================
 *   ========            ======================-   :======================
 *   ========.           =====================:     .=====================
 *   -=======:           ================--:.         .:----==============
 *   .========           ======------------:.          ::-----------======
 *    ========.          =====================:     .-====================:
 *    :========          ======================-   :====================== :
 *     ========:         =======================: .=======================  :
 *     :========         ======================== -=======================  .:
 *      =========        ======================== ========================   -
 *       ========-       ========================.========================   .-
 *       :========-      ========================.========================    =.
 *        :========-     ========================.========================    :-
 *         :=========    ========================.========================    .=.
 *          :=========.  ========================.=======================.    .=-
 *           :=========:.===============================================.     .==
 *            .=======================================================:       .==
 *              ==================================----------------:.          :==
 *               -===============================:                            ===
 *                .==============================:                           .===
 *                  -============================:                           ====
 *                    -==========================:                          ====:
 *                     .=========================:                        .=====
 *                       ========================:                       :=====.
 *                       ========================:                    .:======:
 *                       ========================:                 .:========-
 *                       ===========================-:::......::-===========:
 *                       =================================================-
 *                       ===============================================-.
 *                       ============================================-:
 *                       ===================-...:--=============--:.
 *
 *
 */

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC2981.sol";

struct Nft {
    uint256 maxAmount;
    uint256 preSalePrice;
    uint256 publicPrice;
    uint256 freeClaimStartTime;
    uint256 freeClaimEndTime;
    uint256 preSaleStartTime;
    uint256 preSaleEndTime;
    uint256 publicSaleStartTime;
    uint256 publicSaleEndTime;
    uint256 maxPublicMintAmountPerTx;
    uint256 maxPublicMintAmountPerAddress;
    bytes32 freeClaimMerkleRoot;
    bytes32 preSaleMerkleRoot;
    string tokenURI;
}

contract PlutoLabNFT is ERC1155Supply, ERC2981, Ownable, ReentrancyGuard {
    event ClaimMint(uint256 indexed id, address indexed to, uint256 amount);
    event PreSaleMint(uint256 indexed id, address indexed to, uint256 amount);
    event PublicMint(uint256 indexed id, address indexed to, uint256 amount);

    string private contractLevelURI;
    string public name;
    string public symbol;
    bool public paused;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
        paused = false;
        _setDefaultRoyalty(owner(), 750);
    }

    modifier isNotPaused() {
        require(!paused, "the contract is paused");
        _;
    }

    modifier checkAmount(uint256 _amount) {
        require(_amount > 0, "need to mint at least 1 NFT");
        _;
    }

    modifier checkTotalSupply(uint256 _amount, uint256 _id) {
        require(
            totalSupply(_id) + _amount <= nftList[_id].maxAmount,
            "exceeds max supply"
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    mapping(uint256 => Nft) public nftList;
    mapping(uint256 => mapping(address => uint256)) public freeClaimedAmount;
    mapping(uint256 => mapping(address => uint256)) public preSaleMintedAmount;
    mapping(uint256 => mapping(address => uint256)) public publicMintedAmount;

    function setNftStatus(
        uint256 _id,
        Nft calldata _nft,
        address _receiver,
        uint96 _feeNumerator
    ) external onlyOwner {
        nftList[_id] = _nft;
        _setTokenRoyalty(_id, _receiver, _feeNumerator);
    }

    function setMerkleRoot(
        uint256 _id,
        bytes32 _freeClaimMerkleRoot,
        bytes32 _preSaleMerkleRoot
    ) external onlyOwner {
        nftList[_id].freeClaimMerkleRoot = _freeClaimMerkleRoot;
        nftList[_id].preSaleMerkleRoot = _preSaleMerkleRoot;
    }

    function setContractPaused(bool _toggle) external onlyOwner {
        paused = _toggle;
    }

    function setURI(uint256 _id, string memory _uri) external onlyOwner {
        nftList[_id].tokenURI = _uri;
        emit URI(_uri, _id);
    }

    function setContractURI(string calldata _contractLevelURI)
        external
        onlyOwner
    {
        contractLevelURI = _contractLevelURI;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "not enough balance");
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "failed to withdraw");
    }

    function devMint(uint256 _id, uint256 _amount)
        public
        onlyOwner
        isNotPaused
        checkAmount(_amount)
        checkTotalSupply(_amount, _id)
    {
        _mint(owner(), _id, _amount, "");
    }

    function checkFreeClaimAllowlist(
        uint256 _id,
        address addr,
        uint256 _amount,
        bytes32[] calldata proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr, _amount));
        return
            MerkleProof.verify(proof, nftList[_id].freeClaimMerkleRoot, leaf);
    }

    function checkPreSaleAllowlist(
        uint256 _id,
        address addr,
        uint256 _amount,
        bytes32[] calldata proof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(addr, _amount));
        return MerkleProof.verify(proof, nftList[_id].preSaleMerkleRoot, leaf);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return nftList[_id].tokenURI;
    }

    function contractURI() public view returns (string memory) {
        return contractLevelURI;
    }

    function burn(uint256 _id, uint256 _amount) public {
        _burn(msg.sender, _id, _amount);
    }

    function freeClaim(
        address _to,
        uint256 _id,
        uint256 _mintAmount,
        uint256 _maxAmount,
        bytes32[] calldata proof
    )
        external
        isNotPaused
        checkAmount(_mintAmount)
        checkTotalSupply(_mintAmount, _id)
        nonReentrant
    {
        require(
            block.timestamp >= nftList[_id].freeClaimStartTime &&
                block.timestamp <= nftList[_id].freeClaimEndTime,
            "free claim is closed"
        );
        require(
            checkFreeClaimAllowlist(_id, _to, _maxAmount, proof),
            "not in allowlist"
        );
        require(
            (freeClaimedAmount[_id][_to] + _mintAmount) <= _maxAmount,
            "exceeds max claimable amount"
        );

        freeClaimedAmount[_id][_to] += _mintAmount;
        _mint(_to, _id, _mintAmount, "");
        emit ClaimMint(_id, _to, _mintAmount);
    }

    function preSaleMint(
        address _to,
        uint256 _id,
        uint256 _mintAmount,
        uint256 _maxAmount,
        bytes32[] calldata proof
    )
        external
        payable
        isNotPaused
        checkAmount(_mintAmount)
        checkTotalSupply(_mintAmount, _id)
        nonReentrant
    {
        require(
            block.timestamp >= nftList[_id].preSaleStartTime &&
                block.timestamp <= nftList[_id].preSaleEndTime,
            "pre-sale is closed"
        );
        require(
            (preSaleMintedAmount[_id][_to] + _mintAmount) <= _maxAmount,
            "exceeds max allowable amount"
        );
        require(
            checkPreSaleAllowlist(_id, _to, _maxAmount, proof),
            "not in allowlist"
        );
        uint256 cost = nftList[_id].preSalePrice * _mintAmount;
        require(msg.value >= cost, "incorrect payment");

        preSaleMintedAmount[_id][_to] += _mintAmount;
        _mint(_to, _id, _mintAmount, "");
        emit PreSaleMint(_id, _to, _mintAmount);
    }

    function publicMint(
        address _to,
        uint256 _id,
        uint256 _mintAmount
    )
        external
        payable
        isNotPaused
        checkAmount(_mintAmount)
        checkTotalSupply(_mintAmount, _id)
        nonReentrant
    {
        require(
            block.timestamp >= nftList[_id].publicSaleStartTime &&
                block.timestamp <= nftList[_id].publicSaleEndTime,
            "public sale is closed"
        );
        require(
            _mintAmount <= nftList[_id].maxPublicMintAmountPerTx,
            "exceeds max amount per tx"
        );
        require(
            (publicMintedAmount[_id][_to] + _mintAmount) <=
                nftList[_id].maxPublicMintAmountPerAddress,
            "exceeds max amount per address"
        );
        uint256 cost = nftList[_id].publicPrice * _mintAmount;
        require(msg.value >= cost, "incorrect payment");

        publicMintedAmount[_id][_to] += _mintAmount;
        _mint(_to, _id, _mintAmount, "");
        emit PublicMint(_id, _to, _mintAmount);
    }
}