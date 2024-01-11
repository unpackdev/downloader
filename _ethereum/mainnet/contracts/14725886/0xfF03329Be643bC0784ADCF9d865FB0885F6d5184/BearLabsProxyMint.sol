pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Context.sol";

interface Bearlab {
    function proxyMint(address _address, uint256 _tokenId) external;
}

contract BearLabsProxyMint is Context, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private m_TokenIdCounter;

    event MintByStaked(
        address indexed receiver,
        uint256 indexed numberOfTokens,
        bytes signature
    );

    event MintByWallet(
        address indexed receiver,
        uint256 indexed numberOfTokens
    );

    address private m_MSK = 0x72D7b17bF63322A943d4A2873310a83DcdBc3c8D;
    address private m_BearLab = 0xfC6DfeA7E513Dd4cB554032418B3b9f01cD24274;

    bool private m_IsMintable = false; // false
    uint256 private m_MaxMintPerAddress = 4;
    uint256 private m_MintPrice = 100000 ether; // 100K MSK

    uint256 private m_MintSupply = 101;
    uint256 private m_BaseCounter = 3333;

    address private m_Verify1 = 0x27798F382f4eE811B12f79e5E3035fb5134b3Dbf;
    address private m_Verify2 = 0x7f5467Fd11F4C7C7F143b03883Cda5432545dC13;
    uint256 private m_SignatureLifeTime = 1 minutes * 5;

    mapping(address => uint256) private m_MintCountList;

    constructor() {}

    function _mintDrop(address _address) private {
        m_TokenIdCounter.increment();
        uint256 tokenId = m_BaseCounter.add(m_TokenIdCounter.current());

        require(tokenId <= m_BaseCounter.add(m_MintSupply));

        Bearlab(m_BearLab).proxyMint(_address, tokenId);
        m_MintCountList[_address] = m_MintCountList[_address].add(1);
    }

    function _safeMintMultiple(address _address, uint256 _numberOfTokens)
        private
    {
        while (_numberOfTokens > 0) {
            _mintDrop(_address);
            _numberOfTokens = _numberOfTokens.sub(1);
        }
    }

    function mintByWallet(uint256 _numberOfTokens) public {
        require(m_IsMintable, "must be active");

        require(_numberOfTokens > 0);

        uint256 afterMintBalace = m_MintCountList[_msgSender()].add(
            _numberOfTokens
        );

        require(
            afterMintBalace <= m_MaxMintPerAddress,
            "Over Max Mint per Address"
        );

        IERC20 msk = IERC20(m_MSK);
        uint256 requireAmount = m_MintPrice.mul(_numberOfTokens);

        require(
            msk.balanceOf(_msgSender()) >= requireAmount,
            "Msk balance is not enough"
        );

        msk.transferFrom(_msgSender(), address(this), requireAmount);

        _safeMintMultiple(_msgSender(), _numberOfTokens);

        emit MintByWallet(_msgSender(), _numberOfTokens);
    }

    function mintByStaked(
        uint256 _numberOfTokens,
        uint256 _time,
        bytes memory signature1,
        bytes memory signature2
    ) external {
        require(m_IsMintable, "must be active");

        require(_numberOfTokens > 0);

        uint256 afterMintBalace = m_MintCountList[_msgSender()].add(
            _numberOfTokens
        );

        require(
            afterMintBalace <= m_MaxMintPerAddress,
            "Over Max Mint per Address"
        );

        bytes32 messageHash = getMessageHash(
            _msgSender(),
            _numberOfTokens,
            _time,
            m_MintCountList[_msgSender()]
        );

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        require(
            recoverSigner(ethSignedMessageHash, signature1) == m_Verify1,
            "Different signer1"
        );

        require(
            recoverSigner(ethSignedMessageHash, signature2) == m_Verify2,
            "Different signer2"
        );

        require(block.timestamp - _time < m_SignatureLifeTime);

        _safeMintMultiple(_msgSender(), _numberOfTokens);

        emit MintByStaked(_msgSender(), _numberOfTokens, signature1);
    }

    function getMintCount(address _address) external view returns (uint256) {
        return m_MintCountList[_address];
    }

    ///////////////////////////////////////////////////////////////////

    function resetTokenIdCounter() external onlyOwner {
        m_TokenIdCounter.reset();
    }

    function getCurrentSupply() external view returns (uint256) {
        return m_BaseCounter.add(m_TokenIdCounter.current());
    }

    function setMintEnabled(bool _enabled) external onlyOwner {
        m_IsMintable = _enabled;
    }

    function getMintEnabled() external view returns (bool) {
        return m_IsMintable;
    }

    function setMaxMintPerAddress(uint256 _maxMintPerAddress)
        external
        onlyOwner
    {
        m_MaxMintPerAddress = _maxMintPerAddress;
    }

    function getMaxMintPerAddress() external view returns (uint256) {
        return m_MaxMintPerAddress;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        m_MintPrice = _mintPrice * (10**18);
    }

    function getMintPrice() external view returns (uint256) {
        return m_MintPrice.div(10**18);
    }

    function setBaseCounter(uint256 _baseCounter) external onlyOwner {
        m_BaseCounter = _baseCounter;
    }

    function getBaseCounter() external view returns (uint256) {
        return m_BaseCounter;
    }

    function setMintSupply(uint256 _mintSupply) external onlyOwner {
        m_MintSupply = _mintSupply;
    }

    function getMintSupply() external view returns (uint256) {
        return m_MintSupply;
    }

    function getDropSupply() external view returns (uint256) {
        return m_MintSupply.add(m_BaseCounter);
    }

    function setSignatureLifeTime(uint256 _signatureLifeTime)
        external
        onlyOwner
    {
        m_SignatureLifeTime = _signatureLifeTime;
    }

    function getSignatureLifeTime() external view returns (uint256) {
        return m_SignatureLifeTime;
    }

    // ######## SIGN #########

    function getMessageHash(
        address _address,
        uint256 _amount,
        uint256 _time,
        uint256 _counter
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _amount, _time, _counter));
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    // ######## MSK & BANK & VERIFY #########

    function setMskContract(address _address) external onlyOwner {
        m_MSK = _address;
    }

    function getMskContract() external view returns (address) {
        return m_MSK;
    }

    function setBearlabContract(address _address) external onlyOwner {
        m_BearLab = _address;
    }

    function getBearlabContract() external view returns (address) {
        return m_BearLab;
    }

    function setVerifyAddress1(address _address) external onlyOwner {
        m_Verify1 = _address;
    }

    function getVerfiyAddress1() external view returns (address) {
        return m_Verify1;
    }

    function setVerifyAddress2(address _address) external onlyOwner {
        m_Verify2 = _address;
    }

    function getVerfiyAddress2() external view returns (address) {
        return m_Verify2;
    }

    ////////////////////////////////////////////////////////////////
    function withdrawMsk() external onlyOwner {
        IERC20(m_MSK).transfer(owner(), IERC20(m_MSK).balanceOf(address(this)));
    }
}
