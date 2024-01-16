// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC721AUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

/**
██████╗░██╗░░░██╗░██████╗████████╗██╗░█████╗░███╗░░██╗░██████╗
██╔══██╗╚██╗░██╔╝██╔════╝╚══██╔══╝██║██╔══██╗████╗░██║██╔════╝
██║░░██║░╚████╔╝░╚█████╗░░░░██║░░░██║███████║██╔██╗██║╚█████╗░
██║░░██║░░╚██╔╝░░░╚═══██╗░░░██║░░░██║██╔══██║██║╚████║░╚═══██╗
██████╔╝░░░██║░░░██████╔╝░░░██║░░░██║██║░░██║██║░╚███║██████╔╝
╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚═╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░
*/

/**
 * @title Dystians NFT
 */
contract Dystians is ERC721AUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    // sale type
    enum SaleType {
        ALLOWLIST,
        PUBLIC
    }

    // sale params
    struct SaleParams {
        uint256 pricePerToken;
        uint256 maxPerWallet;
        uint256 supplyCap;
        uint256 saleStartTime;
        uint256 saleStopTime;
    }

    bytes32 public freeMintMerkleRoot;
    bytes32 public allowlistMerkleRoot;
    uint256 public totalSupplyCap;
    string public uri;

    mapping(SaleType => SaleParams) public saleParamsMap;
    mapping(address => mapping(SaleType => uint256)) public mintCountMap;
    mapping(address => bool) public freeMintsMap;

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//

    event NewURI(string uri);
    event FreeMint(address indexed minter, uint256 amount);
    event AllowlistMint(address indexed minter, uint256 amount);
    event PublicMint(address indexed minter, uint256 amount);
    event Giveaway(address indexed beneficiary, uint256 amount);

    /**
     * @dev upgradeable constructor
     */
    function initialize(
        bytes32 _freeMintMerkleRoot,
        bytes32 _allowlistMerkleRoot,
        uint256 _totalSupplyCap,
        string calldata _uri
    ) external initializerERC721A initializer {
        __ERC721A_init("Dystians", "DYST");
        __Ownable_init();
        __Pausable_init();

        setFreeMintMerkleRoot(_freeMintMerkleRoot);
        setAllowlistMerkleRoot(_allowlistMerkleRoot);
        setTotalSupplyCap(_totalSupplyCap);
        setURI(_uri);
    }

    /**
     * @notice mint
     * @param _amount amount to mint
     * @param _proof merkle tree proof
     */
    function mint(uint256 _amount, bytes32[] calldata _proof) external payable whenNotPaused {
        address minter = _msgSender();
        uint256 supplyAfter = totalSupply() + _amount;

        // verify sale access
        SaleType saleType = SaleType.ALLOWLIST;
        SaleParams memory saleParams = saleParamsMap[saleType];
        uint256 mintCountAfter = mintCountMap[minter][saleType] + _amount;
        // solhint-disable-next-line not-rely-on-time
        uint256 currentTimestamp = block.timestamp;
        if (
            currentTimestamp >= saleParams.saleStartTime &&
            currentTimestamp <= saleParams.saleStopTime
        ) {
            // free minters only 1
            if (_isFreeMinter(minter, _proof) && !freeMintsMap[minter]) {
                require(_amount == 1, "only 1 for free");
                freeMintsMap[minter] = true;
                saleParams.pricePerToken = 0;
                emit FreeMint(minter, _amount);
            } else {
                require(_isAllowlistMinter(minter, _proof), "not allowlisted");
                emit AllowlistMint(minter, _amount);
            }
        } else {
            saleType = SaleType.PUBLIC;
            saleParams = saleParamsMap[saleType];
            mintCountAfter = mintCountMap[minter][saleType] + _amount;
            require(
                currentTimestamp >= saleParams.saleStartTime &&
                    currentTimestamp <= saleParams.saleStopTime,
                "sale not active"
            );
            emit PublicMint(minter, _amount);
        }

        // general checks
        // solhint-disable-next-line avoid-tx-origin
        require(minter == tx.origin, "no bots");
        require(mintCountAfter <= saleParams.maxPerWallet, "over max per wallet");
        require(supplyAfter <= saleParams.supplyCap, "over supply cap");
        require(msg.value == saleParams.pricePerToken * _amount, "msg.value != cost");

        // state update
        mintCountMap[minter][saleType] = mintCountAfter;

        // mint
        _mint(minter, _amount);
    }

    /**
     * @notice giveaways
     * @dev only owner
     * @param _beneficiary token receiver
     * @param _amount amount to send
     */
    function giveaway(address _beneficiary, uint256 _amount) external onlyOwner {
        require(_amount != 0, "amount = 0");
        uint256 supplyAfter = totalSupply() + _amount;
        require(supplyAfter <= totalSupplyCap, "over total supply cap");

        _mint(_beneficiary, _amount);
        emit Giveaway(_beneficiary, _amount);
    }

    /**
     * @notice withdraw revenue from sales
     * @dev only owner
     * @param _beneficiary receiver of funds
     * @param _amount amount to withdraw
     */
    function withdrawSaleRevenue(address payable _beneficiary, uint256 _amount) external onlyOwner {
        require(_amount != 0, "amount = 0");
        uint256 balance = getBalance();
        require(_amount <= balance, "insufficient balance");
        payable(_beneficiary).transfer(_amount);
    }

    /**
     * @notice pause sale
     * @dev only owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause sale
     * @dev only owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice set sale type params
     * @dev only owner
     * @param _saleType sale type
     * @param _saleParams sale params
     */
    function setSaleTypeParams(SaleType _saleType, SaleParams calldata _saleParams)
        public
        onlyOwner
    {
        require(_saleParams.pricePerToken != 0, "price = 0");
        require(_saleParams.maxPerWallet != 0, "max per wallet = 0");
        require(_saleParams.supplyCap != 0, "supply cap = 0");
        require(_saleParams.saleStartTime != 0, "sale duration = 0");
        require(_saleParams.saleStopTime != 0, "sale duration = 0");
        saleParamsMap[_saleType] = _saleParams;
    }

    /**
     * @notice set free mint merkle root hash
     * @dev only owner
     * @param _hash new hash
     */
    function setFreeMintMerkleRoot(bytes32 _hash) public onlyOwner {
        freeMintMerkleRoot = _hash;
    }

    /**
     * @notice set allowlist merkle tree root hash
     * @dev only owner
     * @param _hash new hash
     */
    function setAllowlistMerkleRoot(bytes32 _hash) public onlyOwner {
        allowlistMerkleRoot = _hash;
    }

    /**
     * @notice set total supply cap
     * @dev only owner
     * @param _cap total supply cap
     */
    function setTotalSupplyCap(uint256 _cap) public onlyOwner {
        require(_cap != 0, "total supply cap = 0");
        // solhint-disable-next-line reason-string
        require(
            _cap >= totalSupply(),
            "total supply cap must be greater than current total supply"
        );
        totalSupplyCap = _cap;
    }

    /**
     * @notice set uri
     * @dev only owner
     * @param _uri new uri
     */
    function setURI(string calldata _uri) public onlyOwner {
        uri = _uri;
        emit NewURI(_uri);
    }

    /**
     * @notice get ether balance in contract
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _isFreeMinter(address _minter, bytes32[] calldata _proof) private view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_minter));
        return MerkleProofUpgradeable.verify(_proof, freeMintMerkleRoot, leaf);
    }

    function _isAllowlistMinter(address _minter, bytes32[] calldata _proof)
        private
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_minter));
        return MerkleProofUpgradeable.verify(_proof, allowlistMerkleRoot, leaf);
    }
}
