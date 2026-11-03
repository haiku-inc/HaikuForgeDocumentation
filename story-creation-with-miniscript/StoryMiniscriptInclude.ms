_TERMINAL_HALF=0; _TERMINAL_FULL=1; _TERMINAL_HIDDEN=2;    _CENTER=0.5; _BOTTOM=0; _TOP=1; _LEFT=0; _RIGHT=1; _WIDTH_BY_HEIGHT=1.6;    _NITRO_CAPTION_NONE=0; _NITRO_CAPTION_NEXT_MESSAGE=1; _NITRO_CAPTION_NEXT_MISSION=2;    _NO_DEVICE="";    _TOOLBAR_DONT_SHOW_NOTIFICATION = 0; _TOOLBAR_SHOW_NOTIFICATION = 1;

CommandWaiting = { "command":"", "device":"", "arguments":[], "serializedId": null, "performedBySerializedState": 0 }
CommandWaiting.setPerformedBySerializedState = function()
	if self.serializedId != null then
		set_serialized_command_state(self.serializedId, "1")
	end if
end function
CommandWaiting.isPerformed = function()
	tell_check_command_is_performed(self.command)
	if self.serializedId != null and get_serialized_command_state(self.serializedId) == "1" then
		self.performedBySerializedState = 1
		return 1
	end if

	check_pending_command_name(self.command)

	list = getPendingFeedbacks()
	for feedback in list
		if checkCommandFeedback(feedback, self.command, self.device, self.arguments) == 1 then
			clearPendingFeedbacks()
			self.setPerformedBySerializedState()
			return 1
		end if
	end for

	return 0
end function

getCommandWaiting = function(command, device, arguments)
	commandWaiting = new CommandWaiting
	commandWaiting.command  = command
	commandWaiting.arguments = arguments
	return commandWaiting
end function

SequenceStep = { "commandWaiting": null, "action": null }

Sequence = { "steps": [], "currentStepIndex": 0 }
Sequence.isPerformed = function()
	length = len(self.steps)
	if length == 0 then
		println("<color=red>error: current sequence has no steps</color>\n" + stackTrace)
		return 1
	end if
	if self.currentStepIndex >= length then
		return 1
	end if

	for i in range(self.currentStepIndex, length - 1, 1)
		currentStep = self.steps[i]
		if currentStep.commandWaiting == null then
			println("<color=red>error: current step " + i + " has no 'commandWaiting'</color>\n" + stackTrace)
			return 0
		end if

		if currentStep.commandWaiting.isPerformed() == 1 then
			self.currentStepIndex = i + 1
			nitroCaption(0)
			if currentStep["action"] != null and currentStep.commandWaiting.performedBySerializedState == 0 then
				currentStep.action()
			end if
			if i > 0 then
				for j in range(i - 1, 0, -1)
					previousStep = self.steps[j]
					previousStep.commandWaiting.setPerformedBySerializedState()
				end for
			end if
			if self.currentStepIndex >= length then
				return 1
			else
				return 0
			end if
		end if
	end for

	return 0
end function

Hint = { "message": "", "startTime": -1, "targetTime": 0, "wasShown": 0 }

Hint.start = function(message, targetTime)
	self.message = message;
	self.targetTime = targetTime;
	self.startTime = getMissionTimer()
	self.wasShown = 0
end function

Hint.tryShowHint = function()
	if self.wasShown == 0 and self.startTime >= 0 then
		if getMissionTimer() - self.startTime >= self.targetTime then
			showHintNotification(self.message)
			self.wasShown = 1
		end if
	end if
end function

Hint.cancel = function()
	self.startTime = -1
end function
// ########## end of injected code ##########