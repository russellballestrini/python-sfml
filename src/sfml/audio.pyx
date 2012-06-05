#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# pySFML2 - Cython SFML Wrapper for Python
# Copyright 2012, Jonathan De Wachter <dewachter.jonathan@gmail.com>
#
# This software is released under the GPLv3 license.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#from libc.stdlib cimport malloc, free
#from cython.operator cimport preincrement as preinc, dereference as deref

from dsystem cimport Int8, Int16, Int32, Int64
from dsystem cimport Uint8, Uint16, Uint32, Uint64

from dsystem cimport Vector3f

cimport dsystem, daudio

from sfml.system import SFMLException, pop_error_message, push_error_message

ctypedef fused Vector3:
	Vector
	tuple

cdef class Vector:
	cdef public object x
	cdef public object y
	cdef public object z
	
	def __init__(self, x=0, y=0, z=0):
		self.x = x
		self.y = y
		self.z = z
		
	def __repr__(self):
		return "sf.Vector({0}[1:-1])".format(self)

	def __str__(self):
		return "({0}x, {1}y, {2}z)".format(self.x, self.y, self.z)

	def __iter__(self):
		return iter((self.x, self.y, self.z))

cdef Vector vector3f_to_vector(Vector3f* v):
	cdef Vector r = Vector.__new__(Vector)
	r.x = v.x
	r.y = v.y
	r.z = v.z
	return r
	
	
cdef class Listener:
	def __init__(self):
		NotImplementedError("This class is not meant to be instanciated!")

	@classmethod
	def get_global_volume(cls):
		return daudio.listener.getGlobalVolume()

	@classmethod
	def set_global_volume(cls, float volume):
		daudio.listener.setGlobalVolume(volume)

	@classmethod
	def get_position(cls):
		cdef Vector3f v = daudio.listener.getPosition()
		return vector3f_to_vector(&v)
		
	@classmethod
	def set_position(cls, Vector3 position):
		x, y, z = position
		daudio.listener.setPosition(x, y, z)

	@classmethod
	def get_direction(cls):
		cdef Vector3f v = daudio.listener.getDirection()
		return vector3f_to_vector(&v)

	@classmethod
	def set_direction(cls, Vector3 direction):
		x, y, z = direction
		daudio.listener.setPosition(x, y, z)


cdef class Chunk:
	cdef Int16* m_samples
	cdef size_t m_sampleCount

	#def __cinit__(self):
		##print("Somewhere in time I will find you and haunt you again!")
		#self.p_this = new daudio.Chunk()
		
	#def __dealloc__(self):
		#del self.p_this

	def __init__(self): pass
	def __dealloc__(self):
		print("Chunk destroy!")
	
	def __repr__(self): pass
	def __str__(self): pass

	#def __len__(self):
		#return self.p_this.sampleCount
		
	#def __getitem__(self, size_t key):
		#return self.p_this.samples[key]


cdef api object wrap_chunk(Int16* samples, unsigned int sample_count):
	cdef Chunk r = Chunk.__new__(Chunk)
	r.m_samples = samples
	r.m_sampleCount = sample_count
	return r


cdef class SoundBuffer:
	cdef daudio.SoundBuffer *p_this
	cdef bint                delete_this
	
	def __init__(self):
		raise NotImplementedError("Use specific methods")

	def __dealloc__(self):
		if self.delete_this: del self.p_this
			
	def __repr__(self): pass
	def __str__(self): pass

	@classmethod
	def load_from_file(cls, filename):
		cdef daudio.SoundBuffer *p = new daudio.SoundBuffer()
		cdef char* encoded_filename
		
		encoded_filename_temporary = filename.encode('UTF-8')	
		encoded_filename = encoded_filename_temporary
		
		if p.loadFromFile(encoded_filename): return wrap_soundbuffer(p)
		
		del p
		raise SFMLException()

	@classmethod
	def load_from_memory(cls, bytes data):
		cdef daudio.SoundBuffer *p = new daudio.SoundBuffer()
		
		if p.loadFromMemory(<char*>data, len(data)): return wrap_soundbuffer(p)

		del p
		raise SFMLException()

	#@classmethod
	#def load_from_samples(cls, list samples, unsigned int channels_count, unsigned int sample_rate):
		#cdef declaudio.SoundBuffer *p_sb = new declaudio.SoundBuffer()
		#cdef declaudio.Int16 *p_samples = <declaudio.Int16*>malloc(len(samples) * sizeof(declaudio.Int16))
		#cdef declaudio.Int16 *p_temp = NULL

		#if p_samples == NULL:
			#raise SFMLException()
		#else:
			#p_temp = p_samples

			#for sample in samples:
				#p_temp[0] = <int>sample
				#preinc(p_temp)

			#if p_sb.LoadFromSamples(p_samples, len(samples), channels_count, sample_rate):
				#free(p_samples)
				#return wrap_sound_buffer_instance(p_sb, True)
			#else:
				#free(p_samples)
				#raise SFMLException()

	def save_to_file(self, filename):
		cdef char* encoded_filename	
			
		encoded_filename_temporary = filename.encode('UTF-8')	
		encoded_filename = encoded_filename_temporary
		
		self.p_this.saveToFile(encoded_filename)

	#property samples:
		#def __get__(self):
			#cdef declaudio.Int16 *p = <Int16*>self.p_this.getSamples()
			#cdef unsigned int i
			#ret = []

			#for i in range(self.p_this.GetSamplesCount()):
				#ret.append(int(p[i]))

			#return ret

	property sample_count:
		def __get__(self):
			return self.p_this.getSampleCount()

	property sample_rate:
		def __get__(self):
			return self.p_this.getSampleRate()

	property channel_count:
		def __get__(self):
			return self.p_this.getChannelCount()

	property duration:
		def __get__(self):
			return self.p_this.getDuration().asMilliseconds()

cdef SoundBuffer wrap_soundbuffer(daudio.SoundBuffer *p, bint delete_this=True):
	cdef SoundBuffer r = SoundBuffer.__new__(SoundBuffer)
	r.p_this = p
	r.delete_this = delete_this
	return r


cdef class SoundSource:
	STOPPED = daudio.soundsource.Stopped
	PAUSED = daudio.soundsource.Paused
	PLAYING = daudio.soundsource.Playing

	cdef daudio.SoundSource *p_soundsource

	property pitch:
		def __get__(self):
			return self.p_soundsource.getPitch()

		def __set__(self, float pitch):
			self.p_soundsource.setPitch(pitch)

	property volume:
		def __get__(self):
			return self.p_soundsource.getVolume()

		def __set__(self, float volume):
			self.p_soundsource.setVolume(volume)
			
	property position:
		def __get__(self):
			cdef Vector3f v = self.p_soundsource.getPosition()
			return vector3f_to_vector(&v)

		def __set__(self, object position):
			x, y, z = position
			self.p_soundsource.setPosition(x, y, z)

	property relative_to_listener:
		def __get__(self):
			return self.p_soundsource.isRelativeToListener()

		def __set__(self, bint relative):
			self.p_soundsource.setRelativeToListener(relative)
		  
	property min_distance:
		def __get__(self):
			return self.p_soundsource.getMinDistance()

		def __set__(self, float distance):
			self.p_soundsource.setMinDistance(distance)
			
	property attenuation:
		def __get__(self):
			return self.p_soundsource.getAttenuation()

		def __set__(self, float attenuation):
			self.p_soundsource.setAttenuation(attenuation)  


cdef class Sound(SoundSource):
	cdef daudio.Sound *p_this	
	cdef SoundBuffer   m_buffer

	def __init__(self, SoundBuffer buffer=None):
		self.p_this = new daudio.Sound()
		self.p_soundsource = <daudio.SoundSource*>self.p_this
		
		if buffer: self.buffer = buffer

	def __dealloc__(self):
		del self.p_this

	def __repr__(self):
		return "sf.Sound()"
		
	def play(self):
		self.p_this.play()
		
	def pause(self):
		self.p_this.pause()

	def stop(self):
		self.p_this.stop()
		
	property buffer:
		def __get__(self):
			return self.m_buffer

		def __set__(self, SoundBuffer buffer):
			self.p_this.setBuffer(buffer.p_this[0])
			self.m_buffer = buffer			

	property loop:
		def __get__(self):
			return self.p_this.getLoop()

		def __set__(self, bint loop):
			self.p_this.setLoop(loop)

	property playing_offset:
		def __get__(self):
			return self.p_this.getPlayingOffset().asMilliseconds()

		def __set__(self, Uint32 time_offset):
			self.p_this.setPlayingOffset(dsystem.milliseconds(time_offset))

	property status:
		def __get__(self):
			return self.p_this.getStatus()


cdef class SoundStream(SoundSource):
	cdef daudio.SoundStream *p_soundstream
	
	def __init__(self):
		if self.__class__ == SoundStream:
			raise NotImplementedError("SoundStream is abstract")
			
	def play(self):
		self.p_soundstream.play()
		
	def pause(self):
		self.p_soundstream.pause()

	def stop(self):
		self.p_soundstream.stop()

	property channel_count:
		def __get__(self):
			return self.p_soundstream.getChannelCount()
			
	property sample_rate:
		def __get__(self):
			return self.p_soundstream.getSampleRate()

	property status:
		def __get__(self):
			return self.p_soundstream.getStatus()
			
	property playing_offset:
		def __get__(self):
			return self.p_soundstream.getPlayingOffset().asMilliseconds()

		def __set__(self, Uint32 time_offset):
			self.p_soundstream.setPlayingOffset(dsystem.milliseconds(time_offset))
			
	property loop:
		def __get__(self):
			return self.p_soundstream.getLoop()

		def __set__(self, bint loop):
			self.p_soundstream.setLoop(loop)


cdef class Music(SoundStream):
	cdef daudio.Music *p_this
	
	def __init__(self):
		raise NotImplementedError("Use specific constructor")

	def __dealloc__(self):
		del self.p_this

	@classmethod
	def open_from_file(cls, filename):
		cdef daudio.Music *p = new daudio.Music()
		cdef char* encoded_filename	

		encoded_filename_temporary = filename.encode('UTF-8')	
		encoded_filename = encoded_filename_temporary
		
		if p.openFromFile(encoded_filename): return wrap_music(p)
		
		del p
		raise SFMLException()

	@classmethod
	def open_from_memory(cls, bytes data):
		cdef daudio.Music *p = new daudio.Music()

		if p.openFromMemory(<char*>data, len(data)): return wrap_music(p)

		del p
		raise SFMLException()
		
	property duration:
		def __get__(self):
			return self.p_this.getDuration().asMilliseconds()


cdef Music wrap_music(daudio.Music *p):
	cdef Music r = Music.__new__(Music)
	r.p_this = p
	r.p_soundstream = <daudio.SoundStream*>p
	r.p_soundsource = <daudio.SoundSource*>p
	return r


cdef class SoundRecorder:
	cdef daudio.SoundRecorder *p_soundrecorder

	def __init__(self):
		if self.__class__ == SoundRecorder:
			raise NotImplementedError("SoundRecorder is abstract")
		elif self.__class__ is not SoundBufferRecorder:
			self.p_soundrecorder = <daudio.SoundRecorder*>new daudio.DerivableSoundRecorder(<void*>self)

	def __dealloc__(self):
		if self.__class__ is SoundRecorder:
			print("HEINNNNNNNNNNNNn")
			del self.p_soundrecorder
			
	def start(self, unsigned int sample_rate=44100):
		self.p_soundrecorder.start(sample_rate)
		
	def stop(self):
		self.p_soundrecorder.stop()

	property sample_rate:
		def __get__(self):
			return self.p_soundrecorder.getSampleRate()
			
	@classmethod
	def is_available(cls):
		return daudio.soundrecorder.isAvailable()

	def on_start(self):
		print("sf.SoundRecorder.on_start()")
		return True
		
	def on_process_samples(self, chunk, foo):
		print("sf.SoundRecorder.on_process_samples()")
		return True
	
	def on_stop(self):
		print("sf.SoundRecorder.on_stop()")


cdef class SoundBufferRecorder(SoundRecorder):
	cdef daudio.SoundBufferRecorder *p_this
	cdef SoundBuffer                 m_buffer

	def __init__(self):
		self.p_this = new daudio.SoundBufferRecorder()
		self.p_soundrecorder = <daudio.SoundRecorder*>self.p_this

		self.m_buffer = wrap_soundbuffer(<daudio.SoundBuffer*>&self.p_this.getBuffer(), False)
		
	def __dealloc__(self):
		del self.p_this

	property buffer:
		def __get__(self):
			return self.m_buffer