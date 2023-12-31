// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./TransferHelper.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IDonate3.sol";

interface AttestContractInterface {
     function attestUint(bytes32 schema, address donor, address donee, uint256 amount, address token) external returns (bytes32);
}

contract Donate3 is Ownable, IDonate3, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    string public tokenSymbol;

    uint32 handlingFee = 0;

    bytes32 private freeMerkleRoot;

    address attesterAddress;

    bytes32 schemaID;

    event HandleFeeChanged(address from, uint32 feeBefore, uint32 feeAfter);
    event FreeMerkleRootChanged(
        address from,
        bytes32 freeMerkleRootBefore,
        bytes32 freeMerkleRootAfter
    );
    event donateRecord(
        address from,
        address to,
        uint256 amount,
        bytes msg
    );
    event withDraw(string symbol, address from, address to, uint256 amount);

    error CallFailed();

    modifier projectOwnerOrowner(address pOwner) {
        require(msg.sender == pOwner || msg.sender == owner(),
            "caller not contract owner or project owner!");
        _;
    }

    constructor(string memory _tokenSymbol,address _attesterAddress ,bytes32 _schemaID) {
        tokenSymbol = _tokenSymbol;
        attesterAddress = _attesterAddress;
        schemaID = _schemaID;
    }

    receive() external payable {
        //        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    fallback() external payable {
        //        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }

    function setHandleFee(uint32 _fee) external onlyOwner {
        require(_fee <= 200, "Fee out of range.");
        require(_fee != handlingFee, "Fee is equal.");

        emit HandleFeeChanged(_msgSender(), handlingFee, _fee);

        handlingFee = _fee;
    }

    function setFreeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        emit FreeMerkleRootChanged(_msgSender(), freeMerkleRoot, _merkleRoot);

        freeMerkleRoot = _merkleRoot;
    }

    function _verifyFreeAllowList(
        address pOwner,
        bytes32[] calldata _merkleProof
    ) internal view returns (bool) {
        require(pOwner != address(0), "Owner is the zero address.");

        bytes32 leaf = keccak256(abi.encodePacked(pOwner));
        return MerkleProof.verify(_merkleProof, freeMerkleRoot, leaf);
    }

    function donate(
        address _token,
        uint256 _amountInDesired,
        address _to,
        bytes calldata _message,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant{

        address from = _msgSender();
        bytes calldata message = _message;
        address token = _token;
        bytes32[] calldata merkleProof = _merkleProof;
        uint256 amountInDesired = _amountInDesired;
        address to = _to;

        require(address(to) != address(0), "The project is not exist");
        require(from != to, "The donor address is equal to receive");
        require(amountInDesired > 0, "Invalid input amount.");
        
        uint256 amountOut = _getAmount(from, amountInDesired, merkleProof);
        require(amountOut <= amountInDesired, "Invalid output amount");

     
        if(token == address(0)){        //donate ETH
            // transfer
            (bool success, ) = to.call{value: amountOut}("");
            if (!success) {
                revert CallFailed();
            }

            // refund dust eth, if any
            if (msg.value > amountOut) {
                TransferHelper.safeTransferETH(from, msg.value - amountOut);
            }
        }else{
            uint256 amountOut = _transferToken(
                token,
                from,
                amountInDesired,
                to,
                merkleProof
            );
        }
        
        AttestContractInterface attestContract = AttestContractInterface(attesterAddress);
        attestContract.attestUint(schemaID,from, to, amountInDesired, token);

        // record
        _record(from, to, amountOut, message);
    }

    function _transferToken(
        address token,
        address from,
        uint256 amountInDesired,
        address rAddress,
        bytes32[] calldata merkleProof
    ) internal returns (uint256 amountOut) {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        // transfer to contract
        TransferHelper.safeTransferFrom(
            token,
            from,
            address(this),
            amountInDesired
        );

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        uint256 amountIn = balanceAfter - balanceBefore;
        amountOut = _getAmount(from, amountIn, merkleProof);
        require(amountOut <= amountIn, "Invalid output amount");

        // transfer to user
        TransferHelper.safeApprove(token, rAddress, amountOut);
        TransferHelper.safeTransfer(token, rAddress, amountOut);
    }

    function _getAmount(
        address from,
        uint256 amountIn,
        bytes32[] calldata _merkleProof
    ) internal view returns (uint256) {
        uint32 fee = _merkleProof.length > 0 &&
            _verifyFreeAllowList(from, _merkleProof)
            ? 0
            : handlingFee;
        uint256 amountOut = amountIn.mul(uint256(1000).sub(fee)).div(1000);
        return amountOut;
    }

    function _record(
        address from,
        address to,
        uint256 amountOut,
        bytes calldata message
    ) internal {
        //bytes32 symbolBytes = stringToBytes32(symbol);
        emit donateRecord(from, to, amountOut, message);
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function withDrawToken(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");
        require(amount > 0 && amount <= to.balance, "Invalid input amount.");

        // transfer
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            revert CallFailed();
        }
        emit withDraw(tokenSymbol, _msgSender(), to, amount);
    }

    function withDrawERC20List(
        address[] calldata tokens,
        string[] calldata symbols,
        address to,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");
        require(
            tokens.length == symbols.length && symbols.length == amounts.length,
            "Invalid input length"
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            string memory symbol = symbols[i];
            uint256 amount = amounts[i];

            uint256 balance = IERC20(token).balanceOf(address(this));
            require(amount > 0 && amount <= balance, "Invalid input amount.");

            // transfer to user
            TransferHelper.safeApprove(token, to, amount);
            TransferHelper.safeTransfer(token, to, amount);

            emit withDraw(symbol, _msgSender(), to, amount);
        }
    }

    function withDrawERC20(
        address token,
        string calldata symbol,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "ZERO_ADDRESS");

        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount > 0 && amount <= balance, "Invalid input amount.");

        // transfer to user
        TransferHelper.safeApprove(token, to, amount);
        TransferHelper.safeTransfer(token, to, amount);

        emit withDraw(symbol, _msgSender(), to, amount);
    }
}