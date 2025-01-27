

local Align = {}

function Align.new(instance: Instance, posData, oriData)
    local attachment = Instance.new("Attachment")

    -- Create an AlignPosition to use for moving the platform around
    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPosition.Attachment0 = attachment
    alignPosition.MaxForce = posData.MaxForce
    alignPosition.MaxVelocity = posData.MaxVelocity
    alignPosition.Responsiveness = posData.Responsiveness

    -- Create an AlignOrientation to use for rotating the platform
    local alignOrientation = Instance.new("AlignOrientation")
    alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
    alignOrientation.Attachment0 = attachment
    alignOrientation.MaxTorque = oriData.MaxTorque
    alignOrientation.MaxAngularVelocity = oriData.MaxAngularVelocity
    alignOrientation.Responsiveness = oriData.Responsiveness

    attachment.Parent = instance
    alignPosition.Parent = instance
    alignOrientation.Parent = instance

    return {
        attachment = attachment,
        alignPosition = alignPosition,
        alignOrientation = alignOrientation,
    }

end


return Align