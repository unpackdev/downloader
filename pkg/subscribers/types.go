package subscribers

type SubscriberName string

func (s SubscriberName) String() string {
	return string(s)
}

type Status int16

const (
	StatusActive Status = iota
	StatusNotActive
)
