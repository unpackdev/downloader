package subscribers

type SubscriberType string

func (t SubscriberType) String() string {
	return string(t)
}

type Status int16

const (
	StatusActive Status = iota
	StatusNotActive
)
