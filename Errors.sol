contract Errors
{
function Revertion(bool _cond, string _msg)
  	internal
  	pure
  	{
  		if (_cond)
  		{
  			revert(_msg);
  		}
  	}
}