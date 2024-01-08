// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";

import "./IRiddleBrain.sol";
import "./AdminRole.sol";

contract RiddleBrainVault is Ownable, AdminRole {
	using SafeMath for uint;
	using Address for address;

	struct Batch {
		uint32 count;
		uint32 discount;	// percentage of discount e.g 90
	}

	IRiddleBrain internal _riddleBrain;
	mapping(uint => Batch) internal _batchByNum; // batchNum => Batch;
	uint internal _brainPrice;
	uint BRAIN_UNIT = 10 ** 18;

	constructor(address riddleBrain) public onlyOwner {
		_riddleBrain = IRiddleBrain(riddleBrain);
		_batchByNum[100].count = 100;
		_batchByNum[100].discount = 100;
		_batchByNum[200].count = 200;
		_batchByNum[200].discount = 90;
		_batchByNum[500].count = 500;
		_batchByNum[500].discount = 85;
		_batchByNum[1000].count = 1000;
		_batchByNum[1000].discount = 75;
	}

	function getRiddleBrain() public view returns (address) {
		return address(_riddleBrain);
	}

	function getBrainPrice() public view returns (uint) {
		return _brainPrice;
	}

	function countOf(uint batchNum) external view returns (uint32) {
		return _batchByNum[batchNum].count;
	}

	function discountOf(uint batchNum) external view returns (uint32) {
		return _batchByNum[batchNum].discount;
	}

	function getBatchByNumber(uint batchNum) external view returns(uint32 count, uint32 discount) {
		count = _batchByNum[batchNum].count;
		discount = _batchByNum[batchNum].discount;
	}

	function setRiddleBrain(address riddleBrain) public onlyAdmin {
		_riddleBrain = IRiddleBrain(riddleBrain);
	}

	function setBrainPrice(uint price) external onlyAdmin {
		_brainPrice = price;
	}

	function setBrainBatch(uint batchNum, uint32 count, uint32 discount) external onlyAdmin {
		_batchByNum[batchNum] = Batch({
			count: count,
			discount: discount
		});
	}

	function transferBrainBatchTo(address to, uint batchNum) external onlyOwner {
		_riddleBrain.mint(to, _batchByNum[batchNum].count * BRAIN_UNIT);
	}

	function transferBrainsTo(address to, uint amount) external onlyOwner {
		_riddleBrain.mint(to, amount * BRAIN_UNIT);
	}

	function burnBrainsOf(address user, uint amount) external onlyOwner {
		_riddleBrain.burn(user, amount * BRAIN_UNIT);
	}
}
