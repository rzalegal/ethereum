pragma solidity ^0.4.24;
import "./safemath.sol";

contract Security
{
	using safemath for uint8;

	uint8 max;

	mapping (address => uint8) levels;

	constructor(uint8 _maxAccessLevel)
	internal
	{
		max = _maxAccessLevel;
		levels[msg.sender] = max;
	}

	function setAccess(address _sub)
	internal
	{
		levels[_sub] = 1;
	}

	function upgradeAccess(address _sub)
	internal
	{
		levels[_sub]
	}

}