pragma solidity ^0.4.23;

import "Multiownable.sol";
import "IProposal.sol";

contract Multisig is Multiownable
{
	uint256 public timeout;

	mapping (bytes32 => uint256) public initiationTimeByOperation;

	event TimeoutExpired(bytes32 operation);

	event OperationCreatedWithParams(bytes32 indexed operation, address contractAddress, bytes data);

	modifier onlyNotExpired(address contractAddress, bytes data)
	{
		bytes32 operation = keccak256(msg.data, ownersGeneration);
		if (initiationTimeByOperation[operation] == 0)
		{
			initiationTimeByOperation[operation] = block.timestamp;
			emit OperationCreatedWithParams(operation, contractAddress, data);
		}

		if (block.timestamp - initiationTimeByOperation[operation] > timeout)
		{
			initiationTimeByOperation[operation] = 0;
			deleteOperation(operation);

			emit TimeoutExpired(operation);
		}
		else
		{
			_;
		}
	}

	constructor(uint256 _timeout) Multiownable() public
	{
		timeout = _timeout;
	}

	function voteForCall(address to, bytes data) external onlyNotExpired(to, data) onlyManyOwners()
	{
		bool success = to.call(data);
		require(success, "call failed");
	}

	function getOwners() external view returns (address[])
	{
		return owners;
	}

	function voteForDelegatecall(address proposal) external onlyNotExpired(proposal, "") onlyManyOwners()
	{
		proposal.delegatecall(abi.encodeWithSignature("execute()"));
	}
}