pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./BlackholePrevention.sol";

contract AirdropDistribution is Ownable, BlackholePrevention {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public dto;

    event Claim(address user, uint256 time, uint256 amount);
    mapping(uint256 => mapping(address => bool)) public mappingClaimWithTime;

    mapping(address => bool) public mappingApprover;
    mapping(address => uint256) public totalDTO;
    mapping(address => uint256) public totalTime;
    mapping(uint256 => uint256) public mappingStartBlock;
    mapping(uint256 => uint256) public mappingEndBlock;

    constructor() {
        dto = IERC20(0xB57420FaD6731B004309D5a0ec7C6C906Adb8df7);
        mappingApprover[0x35131E6E8321Ad2eBE666baC18CB113682023be6] = true;
        mappingStartBlock[1] = block.number;
        mappingEndBlock[1] = block.number + 206000;
    }

    function addApprover(address _approver, bool _val) public onlyOwner {
        mappingApprover[_approver] = _val;
    }

    function verifySignature(
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes32 signedData
    ) internal view returns (bool) {
        address signer = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", signedData)
            ),
            v,
            r,
            s
        );

        return mappingApprover[signer];
    }

    function updateDTOContract(address token) public onlyOwner {
        dto = IERC20(token);
    }

    function claim(
        uint256 time,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        require(time > 0);
        require(
            block.number >= mappingStartBlock[time],
            "Claim time still not start"
        );
        require(block.number <= mappingEndBlock[time], "Claim time is end");
        bytes32 message = keccak256(abi.encode(msg.sender, time, amount));
        require(verifySignature(r, s, v, message), "Signature invalid");
        require(!mappingClaimWithTime[time][msg.sender], "Cannot claim again");

        mappingClaimWithTime[time][msg.sender] = true;

        dto.safeTransfer(msg.sender, amount);
        totalDTO[msg.sender] = totalDTO[msg.sender].add(amount);
        totalTime[msg.sender] = totalTime[msg.sender].add(1);
        emit Claim(msg.sender, time, amount);
    }

    function setStartBlock(uint256 time, uint256 startBlock) public onlyOwner {
        mappingStartBlock[time] = startBlock;
    }

    function setEndBlock(uint256 time, uint256 endBlock) public onlyOwner {
        mappingEndBlock[time] = endBlock;
    }

    function withdrawEther(address payable receiver, uint256 amount)
        external
        virtual
        onlyOwner
    {
        _withdrawEther(receiver, amount);
    }

    function withdrawERC20(
        address payable receiver,
        address tokenAddress,
        uint256 amount
    ) public virtual onlyOwner {
        _withdrawERC20(receiver, tokenAddress, amount);
    }

    function withdrawERC721(
        address payable receiver,
        address tokenAddress,
        uint256 tokenId
    ) external virtual onlyOwner {
        _withdrawERC721(receiver, tokenAddress, tokenId);
    }
}
