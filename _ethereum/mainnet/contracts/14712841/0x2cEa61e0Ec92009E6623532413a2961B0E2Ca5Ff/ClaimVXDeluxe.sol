//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./BearsDeluxeI.sol";
import "./HoneyTokenI.sol";
import "./VXDeluxeI.sol";
import "./console.sol";

contract ClaimVXDeluxe is ReentrancyGuard, Ownable {
    bytes32 public merkleRoot;

    BearsDeluxeI public bearsDeluxe;
    HoneyTokenI public honey;
    VXDeluxeI public vxDeluxe;

    uint16[] public forfeitIds;
    uint256 public customVX = 6900;
    uint256 public whitelistVX = 8400;
    uint256 public forfeitIndex = 0;

    uint256 public price = 0.069 ether;
    uint256 public honeyPrice = 100 ether;

    bool public publicMintOpen = false;
    bool public claimingOpen = false;
    bool public whitelistOpen = false;

    mapping(address => uint256) public claimedPerWallet;
    mapping(uint256 => bool) public forfeitedIds;

    event ClaimedBears(address indexed _owner, uint16[] _ids, uint16[] _bearsIds);
    event ClaimedWhitelist(address indexed _owner, uint16[] _ids);
    event Claimed(address indexed _owner, uint16[] _ids);
    event ChangedPrice(uint256 _price);
    event MerkleRootChanged(bytes32 _merkleRoot);
    event SetContract(address _contract, string _type);
    event ChangedIdIndex(uint256 _newIndex);
    event PublicMint(address indexed _owner, uint16[] ids);
    event PublicMintToggled(bool isOpen);
    event WhiteListMintToggled(bool isOpen);
    event ClaimingToggled(bool isOpen);

    error NotOwner();
    error AlreadyMinted();
    error MaxSupplyReached();
    error WrongAmount();
    error WrongLeaf();
    error WrongProof();
    error CapReached();
    error PublicMintClosed();
    error ClaimingClosed();
    error WhiteListClosed();

    constructor(
        BearsDeluxeI _bearsDeluxe,
        HoneyTokenI _honey,
        VXDeluxeI _vxDeluxe
    ) {
        bearsDeluxe = _bearsDeluxe;
        honey = _honey;
        vxDeluxe = _vxDeluxe;
    }

    // solhint-disable-next-line
    function claimBearsDeluxe(
        uint16[] calldata _tokenIds,
        bool _forfeith,
        bool payHoney
    ) external payable nonReentrant {
        if (claimingOpen == false) revert ClaimingClosed();

        uint256 i;
        uint16[] memory ids = new uint16[](_tokenIds.length);
        uint256 totalPriceToPay;
        uint256 _price = payHoney ? honeyPrice : price;
        for (i; i < _tokenIds.length; ) {
            unchecked {
                uint16 currentToken = _tokenIds[i];
                if (bearsDeluxe.ownerOf(currentToken) != msg.sender) revert NotOwner();
                if (_forfeith) {
                    if (customVX >= vxDeluxe.MAX_SUPPLY()) {
                        revert MaxSupplyReached();
                    }
                    ids[i] = uint16(++customVX);
                    totalPriceToPay += _price;
                    if (forfeitedIds[currentToken]) revert AlreadyMinted();
                    forfeitIds.push(currentToken);
                    forfeitedIds[currentToken] = true;
                } else {
                    if (vxDeluxe.exists(currentToken)) revert AlreadyMinted();
                    ids[i] = currentToken;
                    totalPriceToPay += _price;
                }
                i++;
            }
        }

        if (payHoney == true) {
            if (honey.balanceOf(msg.sender) < totalPriceToPay) revert WrongAmount();
            honey.burn(msg.sender, totalPriceToPay);
        } else {
            if (msg.value != totalPriceToPay) revert WrongAmount();
        }

        vxDeluxe.mintBatch(msg.sender, ids);
        emit ClaimedBears(msg.sender, ids, _tokenIds);
    }

    function claimWhitelist(
        uint256 _amount,
        uint16 _whitelistedAmount,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        if (whitelistOpen == false) revert WhiteListClosed();
        if (_amount > _whitelistedAmount) revert WrongAmount();

        //check merkle
        if (!MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _whitelistedAmount))))
            revert WrongProof();

        //checking how much he already minted
        if (claimedPerWallet[msg.sender] >= _amount) revert CapReached();
        _amount -= claimedPerWallet[msg.sender];
        uint16[] memory ids = new uint16[](_amount);
        uint256 i;
        for (i; i < _amount; ) {
            unchecked {
                if (customVX >= vxDeluxe.MAX_SUPPLY()) revert MaxSupplyReached();
                ids[i] = uint16(++customVX);
                i++;
            }
        }

        claimedPerWallet[msg.sender] += _amount;

        if (msg.value != price * _amount) revert WrongAmount();
        vxDeluxe.mintBatch(msg.sender, ids);
        emit ClaimedWhitelist(msg.sender, ids);
    }

    function claimWhitelistWithHoney(
        uint256 _amount,
        uint16 _whitelistedAmount,
        bytes32[] calldata _merkleProof
    ) external nonReentrant {
        if (whitelistOpen == false) revert WhiteListClosed();
        if (_amount > _whitelistedAmount) revert WrongAmount();

        //check merkle
        if (!MerkleProof.verify(_merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender, _whitelistedAmount))))
            revert WrongProof();

        //checking how much he already minted
        if (claimedPerWallet[msg.sender] >= _amount) revert CapReached();
        _amount -= claimedPerWallet[msg.sender];
        uint16[] memory ids = new uint16[](_amount);
        uint256 i;
        for (i; i < _amount; ) {
            unchecked {
                if (customVX >= vxDeluxe.MAX_SUPPLY()) revert MaxSupplyReached();
                ids[i] = uint16(++customVX);
                i++;
            }
        }

        claimedPerWallet[msg.sender] += _amount;

        if (honey.balanceOf(msg.sender) < (honeyPrice * _amount)) revert WrongAmount();
        honey.burn(msg.sender, (honeyPrice * _amount));
        vxDeluxe.mintBatch(msg.sender, ids);
        emit ClaimedWhitelist(msg.sender, ids);
    }

    function publicMint(bool payHoney, uint256 _amount) external payable nonReentrant {
        if (publicMintOpen == false) revert PublicMintClosed();
        if (customVX + _amount > vxDeluxe.MAX_SUPPLY()) revert MaxSupplyReached();
        require(_amount <= 10 && _amount > 0, "Max 10 mint per tx, min 1");

        uint256 totalPriceToPay;
        uint16[] memory ids = new uint16[](_amount);
        uint256 i;
        uint256 _price = payHoney ? honeyPrice : price;

        for (i; i < _amount; ) {
            unchecked {
                ids[i] = uint16(++customVX);
                totalPriceToPay += _price;
                i++;
            }
        }

        if (payHoney == true) {
            if (honey.balanceOf(msg.sender) < totalPriceToPay) revert WrongAmount();
            honey.burn(msg.sender, totalPriceToPay);
        } else {
            if (msg.value != totalPriceToPay) revert WrongAmount();
        }

        vxDeluxe.mintBatch(msg.sender, ids);
        emit PublicMint(msg.sender, ids);
    }

    function mintSpares(bool payHoney, uint256 _amount) external payable nonReentrant {
        if (publicMintOpen == false) revert PublicMintClosed();
        if (forfeitIndex + _amount > forfeitIds.length) revert MaxSupplyReached();
        require(_amount <= 10 && _amount > 0, "Max 10 mint per tx, min 1");

        uint256 i = forfeitIndex;
        uint16[] memory ids = new uint16[](_amount);
        uint256 totalPriceToPay;
        uint256 _price = payHoney ? honeyPrice : price;
        uint256 index;
        for (i; i < forfeitIndex + _amount; ) {
            unchecked {
                require(forfeitedIds[forfeitIds[i]] == true, "bear not foreited");
                ids[index] = forfeitIds[i];
                totalPriceToPay += _price;
                i++;
                index++;
            }
        }

        forfeitIndex = forfeitIndex + _amount;

        if (payHoney == true) {
            if (honey.balanceOf(msg.sender) < totalPriceToPay) revert WrongAmount();
            honey.burn(msg.sender, totalPriceToPay);
        } else {
            if (msg.value != totalPriceToPay) revert WrongAmount();
        }

        vxDeluxe.mintBatch(msg.sender, ids);
        emit PublicMint(msg.sender, ids);
    }

    function getAllForfeithIds() external view returns (uint16[] memory) {
        return forfeitIds;
    }

    function getPublicMintStatus() external view returns (bool) {
        return publicMintOpen;
    }

    function getClaimingStatus() external view returns (bool) {
        return claimingOpen;
    }

    function getWhiteListStatus() external view returns (bool) {
        return whitelistOpen;
    }

    function setBearsDeluxe(BearsDeluxeI _bearsDeluxe) external onlyOwner {
        bearsDeluxe = _bearsDeluxe;
        emit SetContract(address(_bearsDeluxe), "BearsDeluxe");
    }

    function setHoney(HoneyTokenI _honey) external onlyOwner {
        honey = _honey;
        emit SetContract(address(_honey), "HoneyToken");
    }

    function setVXBears(VXDeluxeI _vxDeluxe) external onlyOwner {
        vxDeluxe = _vxDeluxe;
        emit SetContract(address(_vxDeluxe), "VXDeluxe");
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
        emit ChangedPrice(_newPrice);
    }

    function setPublicMint(bool isOpen) external onlyOwner {
        publicMintOpen = isOpen;
        emit PublicMintToggled(isOpen);
    }

    function setWl(bool isOpen) external onlyOwner {
        whitelistOpen = isOpen;
        emit PublicMintToggled(isOpen);
    }

    function setClaiming(bool isOpen) external onlyOwner {
        claimingOpen = isOpen;
        emit PublicMintToggled(isOpen);
    }

    function setHoneyPrice(uint256 _newPrice) external onlyOwner {
        honeyPrice = _newPrice;
        emit ChangedPrice(_newPrice);
    }

    function setCustomVX(uint256 _newCustomVX) external onlyOwner {
        customVX = _newCustomVX;
        emit ChangedIdIndex(_newCustomVX);
    }

    function setWhitelistVX(uint256 _newWhitelistVX) external onlyOwner {
        whitelistVX = _newWhitelistVX;
        emit ChangedIdIndex(_newWhitelistVX);
    }

    function withdrawEther() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    /**
     * @notice sets merkle root
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }
}
