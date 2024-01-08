// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

library SortitionSumTreeFactory {
    struct SortitionSumTree {
        uint K; 
        uint[] stack;
        uint[] nodes;
        mapping(bytes32 => uint) IDsToNodeIndexes;
        mapping(uint => bytes32) nodeIndexesToIDs;
    }

    struct SortitionSumTrees {
        mapping(bytes32 => SortitionSumTree) sortitionSumTrees;
    }

    function createTree(SortitionSumTrees storage self, bytes32 _key, uint _K) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        require(tree.K == 0, "Tree already exists.");
        require(_K > 1, "K must be greater than one.");
        tree.K = _K;
        tree.stack = new uint[](0);
        tree.nodes = new uint[](0);
        tree.nodes.push(0);
    }

    function set(SortitionSumTrees storage self, bytes32 _key, uint _value, bytes32 _ID) internal {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) { 
            if (_value != 0) { 
                if (tree.stack.length == 0) { 
                    treeIndex = tree.nodes.length;
                    tree.nodes.push(_value);

                    if (treeIndex != 1 && (treeIndex - 1) % tree.K == 0) { 
                        uint parentIndex = treeIndex / tree.K;
                        bytes32 parentID = tree.nodeIndexesToIDs[parentIndex];
                        uint newIndex = treeIndex + 1;
                        tree.nodes.push(tree.nodes[parentIndex]);
                        delete tree.nodeIndexesToIDs[parentIndex];
                        tree.IDsToNodeIndexes[parentID] = newIndex;
                        tree.nodeIndexesToIDs[newIndex] = parentID;
                    }
                } else { 
                    treeIndex = tree.stack[tree.stack.length - 1];
                    tree.stack.pop();
                    tree.nodes[treeIndex] = _value;
                }

                tree.IDsToNodeIndexes[_ID] = treeIndex;
                tree.nodeIndexesToIDs[treeIndex] = _ID;

                updateParents(self, _key, treeIndex, true, _value);
            }
        } else { 
            if (_value == 0) { 
                uint value = tree.nodes[treeIndex];
                tree.nodes[treeIndex] = 0;
                tree.stack.push(treeIndex);
                delete tree.IDsToNodeIndexes[_ID];
                delete tree.nodeIndexesToIDs[treeIndex];

                updateParents(self, _key, treeIndex, false, value);
            } else if (_value != tree.nodes[treeIndex]) { 
                // Set.
                bool plusOrMinus = tree.nodes[treeIndex] <= _value;
                uint plusOrMinusValue = plusOrMinus ? _value - tree.nodes[treeIndex] : tree.nodes[treeIndex] - _value;
                tree.nodes[treeIndex] = _value;

                updateParents(self, _key, treeIndex, plusOrMinus, plusOrMinusValue);
            }
        }
    }

    function queryLeafs(
        SortitionSumTrees storage self,
        bytes32 _key,
        uint _cursor,
        uint _count
    ) internal view returns(uint startIndex, uint[] memory values, bool hasMore) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        for (uint i = 0; i < tree.nodes.length; i++) {
            if ((tree.K * i) + 1 >= tree.nodes.length) {
                startIndex = i;
                break;
            }
        }

        uint loopStartIndex = startIndex + _cursor;
        values = new uint[](loopStartIndex + _count > tree.nodes.length ? tree.nodes.length - loopStartIndex : _count);
        uint valuesIndex = 0;
        for (uint j = loopStartIndex; j < tree.nodes.length; j++) {
            if (valuesIndex < _count) {
                values[valuesIndex] = tree.nodes[j];
                valuesIndex++;
            } else {
                hasMore = true;
                break;
            }
        }
    }

    function draw(SortitionSumTrees storage self, bytes32 _key, uint _drawnNumber) internal view returns(bytes32 ID) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = 0;
        uint currentDrawnNumber = _drawnNumber % tree.nodes[0];

        while ((tree.K * treeIndex) + 1 < tree.nodes.length)  
            for (uint i = 1; i <= tree.K; i++) { 
                uint nodeIndex = (tree.K * treeIndex) + i;
                uint nodeValue = tree.nodes[nodeIndex];

                if (currentDrawnNumber >= nodeValue) currentDrawnNumber -= nodeValue; 
                else { 
                    treeIndex = nodeIndex;
                    break;
                }
            }
        
        ID = tree.nodeIndexesToIDs[treeIndex];
    }

    function stakeOf(SortitionSumTrees storage self, bytes32 _key, bytes32 _ID) internal view returns(uint value) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        uint treeIndex = tree.IDsToNodeIndexes[_ID];

        if (treeIndex == 0) value = 0;
        else value = tree.nodes[treeIndex];
    }

    function total(SortitionSumTrees storage self, bytes32 _key) internal view returns (uint) {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];
        if (tree.nodes.length == 0) {
            return 0;
        } else {
            return tree.nodes[0];
        }
    }

    function updateParents(SortitionSumTrees storage self, bytes32 _key, uint _treeIndex, bool _plusOrMinus, uint _value) private {
        SortitionSumTree storage tree = self.sortitionSumTrees[_key];

        uint parentIndex = _treeIndex;
        while (parentIndex != 0) {
            parentIndex = (parentIndex - 1) / tree.K;
            tree.nodes[parentIndex] = _plusOrMinus ? tree.nodes[parentIndex] + _value : tree.nodes[parentIndex] - _value;
        }
    }
}